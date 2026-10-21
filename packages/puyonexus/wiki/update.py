#!/usr/bin/env python3
# Experimental updater that also updates skins/extensions to compatible versions
import argparse
from concurrent.futures import ThreadPoolExecutor
import difflib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import quote


FILES = ("default.nix", "hashes.nix", "composer.lock")
VERSION = re.compile(r'  version = "(\d+\.\d+\.\d+)";')
MODULE = re.compile(
    r'mkWikimedia(?P<kind>Extension|Skin) \{\s*'
    r'name = "(?P<name>[\w]+)";\s*'
    r'rev = "(?P<rev>[^"\n]+)";\s*'
    r'hash = "(?P<hash>sha256-[^"\n]+)";\s*\}'
)
THIRD_PARTY = re.compile(
    r'mkExtension "(?P<name>[\w]+)" \(fetchFromGitHub \{\s*'
    r'owner = "(?P<owner>[\w-]+)";\s*'
    r'repo = "(?P<repo>[\w.-]+)";\s*'
    r'rev = "(?P<rev>[^"\n]+)";\s*'
    r'hash = "(?P<hash>sha256-[^"\n]+)";\s*\}\)'
)
CORE = re.compile(
    r'fetchFromGitHub \{\s*owner = "Wikimedia";\s*repo = "mediawiki";\s*'
    r'rev = "(?P<rev>[^"\n]+)";\s*hash = "(?P<hash>sha256-[^"\n]+)";\s*\}'
)


class UpdateError(Exception):
    pass


def log(message):
    print(message, file=sys.stderr, flush=True)


def run(*args, cwd=None, env=None):
    result = subprocess.run(args, cwd=cwd, env=env, text=True, stdout=subprocess.PIPE)
    if result.returncode:
        if result.stdout:
            log(result.stdout)
        raise UpdateError(f"Command failed ({result.returncode}): {' '.join(map(str, args))}")
    return result.stdout.strip()


def nix_string(value):
    return json.dumps(str(value)).replace("${", r"\${")


def replace_one(pattern, replacement, text):
    updated, count = re.subn(pattern, lambda _: replacement, text)
    if count != 1:
        raise UpdateError(f"Expected exactly one match for {pattern!r}, found {count}")
    return updated


def replace_pin(match, rev, hash_value):
    text = match[0]
    text = replace_one(r'rev = "[^"\n]+";', f"rev = {nix_string(rev)};", text)
    return replace_one(r'hash = "[^"\n]+";', f"hash = {nix_string(hash_value)};", text)


def remote_refs(owner, repo, *patterns):
    output = run("git", "ls-remote", f"https://github.com/{owner}/{repo}.git", *patterns)
    refs = {}
    for line in output.splitlines():
        commit, ref = line.split("\t")
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise UpdateError(f"Invalid commit returned for {owner}/{repo}: {commit}")
        refs[ref] = commit
    return refs


def resolve_ref(owner, repo, ref):
    if re.fullmatch(r"[0-9a-f]{40}", ref):
        return ref
    if not ref.startswith("refs/"):
        raise UpdateError(f"Use a full ref (refs/tags/... or refs/heads/...) or commit: {ref}")
    refs = remote_refs(owner, repo, ref, ref + "^{}")
    if ref not in refs:
        raise UpdateError(f"{owner}/{repo} has no {ref}; its update policy needs manual review")
    return refs.get(ref + "^{}", refs[ref])


def select_release(current, requested, refs):
    series = current.rsplit(".", 1)[0]
    versions = {
        ref.removeprefix("refs/tags/")
        for ref in refs
        if re.fullmatch(r"refs/tags/" + re.escape(series) + r"\.\d+", ref)
    }
    if not versions:
        raise UpdateError(f"No stable MediaWiki tags found for {series}")
    version = requested or max(versions, key=lambda v: tuple(map(int, v.split("."))))
    if version not in versions:
        raise UpdateError(f"{version} is not a stable release in the current {series} series")
    if int(version.split(".")[-1]) < int(current.split(".")[-1]):
        raise UpdateError(f"Refusing to downgrade MediaWiki from {current} to {version}")
    ref = "refs/tags/" + version
    return version, refs.get(ref + "^{}", refs[ref])


def release_modules(work, commit):
    git_dir = work / "mediawiki-git"
    run("git", "init", "--quiet", str(git_dir))
    run("git", "-C", str(git_dir), "fetch", "--quiet", "--depth=1", "--filter=blob:none",
        "https://github.com/wikimedia/mediawiki.git", commit)
    tree = run("git", "-C", str(git_dir), "ls-tree", "-r", "FETCH_HEAD", "extensions/", "skins/")
    modules = {}
    for line in tree.splitlines():
        metadata, path = line.split("\t", 1)
        mode, kind, rev = metadata.split()
        if mode == "160000" and kind == "commit":
            if not re.fullmatch(r"(extensions|skins)/\w+", path):
                raise UpdateError(f"Unexpected release submodule path: {path}")
            modules[path] = rev
    if not modules:
        raise UpdateError("MediaWiki's release tree contains no extension/skin submodules")
    return modules


def prefetch_archive(owner, repo, rev):
    url = f"https://codeload.github.com/{owner}/{repo}/tar.gz/{quote(rev, safe='/')}"
    result = json.loads(run("nix", "store", "prefetch-file", "--json", "--unpack",
                            "--name", "source", url))
    value = result["hash"]
    if not re.fullmatch(r"sha256-[A-Za-z0-9+/]{43}=", value):
        raise UpdateError(f"Unexpected archive hash for {repo}: {value}")
    return value, Path(result["storePath"])


def archive_hash(owner, repo, rev):
    return prefetch_archive(owner, repo, rev)[0]


class ComposerTools:
    def __init__(self, context):
        self.composer = build(context, "pkgs.php.packages.composer")
        self.php = build(context, "pkgs.php") / "bin/php"
        self.php_version = run(str(self.php), "-r", "echo PHP_VERSION;")

    def satisfies(self, version, constraint):
        if not isinstance(constraint, str) or not constraint.strip():
            raise UpdateError(f"Invalid version constraint: {constraint!r}")
        code = ('require $argv[1]; '
                'echo Composer\\Semver\\Semver::satisfies($argv[2], $argv[3]) ? "yes" : "no";')
        return run(str(self.php), "-r", code,
                   str(self.composer / "share/php/composer/vendor/autoload.php"),
                   version, constraint) == "yes"


def stable_tags(refs):
    releases = []
    for ref, commit in refs.items():
        match = re.fullmatch(r"refs/tags/v?(\d+(?:\.\d+){1,3})", ref)
        if match:
            parts = tuple(map(int, match[1].split(".")))
            releases.append((parts + (0,) * (4 - len(parts)), ref, refs.get(ref + "^{}", commit)))
    return sorted(releases, reverse=True)


def select_extension(match, version, override, composer):
    name, owner, repo = match["name"], match["owner"], match["repo"]
    if override:
        candidates = [((), override, resolve_ref(owner, repo, override))]
    else:
        releases = stable_tags(remote_refs(owner, repo, "refs/tags/*"))
        current_ref = match["rev"]
        if not current_ref.startswith("refs/"):
            current_ref = "refs/tags/" + current_ref
        current = [v for v, ref, commit in releases if ref == current_ref or commit == match["rev"]]
        if not current:
            raise UpdateError(f"Cannot map {name}'s current pin to a stable tag; use --ref {name}=...")
        candidates = [item for item in releases if item[0] >= max(current)]
    for _, ref, commit in candidates:
        hash_value, source = prefetch_archive(owner, repo, commit)
        manifest = json.loads((source / "extension.json").read_text())
        requires = manifest.get("requires", {})
        constraint = requires.get("MediaWiki")
        if constraint is None:
            log(f"Skipping {name} {ref}: no declared MediaWiki compatibility")
            continue
        if not composer.satisfies(version, constraint):
            log(f"Skipping {name} {ref}: requires MediaWiki {constraint}")
            continue
        php_constraint = requires.get("platform", {}).get("php")
        if php_constraint and not composer.satisfies(composer.php_version, php_constraint):
            log(f"Skipping {name} {ref}: requires PHP {php_constraint}")
            continue
        log(f"{name}: {ref} -> {commit} (MediaWiki {constraint})")
        return commit, hash_value
    raise UpdateError(f"No compatible release found for {name} without downgrading")


def render_hashes(version, commit, core_hash, pins):
    lines = ["# DO NOT EDIT THIS FILE! It is generated by update.py.", "{"]
    for field, value in (("name", "mediawiki"), ("tag", version), ("rev", commit), ("hash", core_hash)):
        lines.append(f"  mediawiki.{field} = {nix_string(value)};")
    for path, (rev, hash_value) in sorted(pins.items()):
        kind, name = path.split("/")
        for field, value in (("name", name), ("rev", rev), ("hash", hash_value)):
            lines.append(f"  {kind}.{name}.{field} = {nix_string(value)};")
    return "\n".join(lines + ["}", ""])


def update_sources(original, work, requested, overrides, jobs, composer):
    versions = VERSION.findall(original)
    if len(versions) != 1 or len(list(CORE.finditer(original))) != 1:
        raise UpdateError("Cannot identify the MediaWiki version and source in default.nix")
    inline = list(MODULE.finditer(original))
    third_party = list(THIRD_PARTY.finditer(original))
    if len(inline) != len(re.findall(r"mkWikimedia(?:Extension|Skin) \{", original)):
        raise UpdateError("Unrecognized inline Wikimedia source; update the script's parser")
    helper = re.findall(
        r'fetchFromGitHub \{\s*inherit rev hash;\s*owner = "Wikimedia";\s*'
        r'repo = "mediawiki-\$\{type\}-\$\{name\}";\s*\}', original
    )
    if len(helper) != 1 or len(third_party) + 2 != len(re.findall(r"fetchFromGitHub \{", original)):
        raise UpdateError("Unrecognized GitHub source; update the script's parser")
    unknown = overrides.keys() - {m["name"] for m in third_party}
    if unknown:
        raise UpdateError(f"Unknown third-party extension override(s): {', '.join(sorted(unknown))}")
    current = versions[0]
    series = current.rsplit(".", 1)[0]
    refs = remote_refs("wikimedia", "mediawiki", f"refs/tags/{series}.*")
    version, commit = select_release(current, requested, refs)
    log(f"MediaWiki {current} -> {version} ({commit})")
    modules = release_modules(work, commit)
    required = set(re.findall(r"wikimedia\.(extensions|skins)\.(\w+)", original))
    missing = {f"{kind}/{name}" for kind, name in required} - modules.keys()
    if missing:
        raise UpdateError(f"Release is missing required bundled modules: {', '.join(sorted(missing))}")

    sources = {path: ("wikimedia", "mediawiki-" + path.replace("/", "-"), rev)
               for path, rev in modules.items()}
    branch = "refs/heads/REL" + series.replace(".", "_")
    for match in inline:
        kind = "extensions" if match["kind"] == "Extension" else "skins"
        path = f"{kind}/{match['name']}"
        if path not in sources:
            repo = "mediawiki-" + path.replace("/", "-")
            rev = resolve_ref("wikimedia", repo, branch)
            sources[path] = ("wikimedia", repo, rev)
            log(f"{path}: {branch} -> {rev}")
        else:
            log(f"{path}: using bundled release revision")
    third_pins = {
        match["name"]: select_extension(match, version, overrides.get(match["name"]), composer)
        for match in third_party
    }
    sources["mediawiki"] = ("wikimedia", "mediawiki", commit)

    def prefetch(item):
        path, (owner, repo, rev) = item
        log(f"Hashing {path}")
        return path, (rev, archive_hash(owner, repo, rev))

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        pins = dict(pool.map(prefetch, sources.items()))
    updated = replace_one(VERSION, f'  version = "{version}";', original)
    updated = CORE.sub(lambda m: replace_pin(m, *pins["mediawiki"]), updated)

    def inline_pin(match):
        kind = "extensions" if match["kind"] == "Extension" else "skins"
        return replace_pin(match, *pins[f"{kind}/{match['name']}"])

    updated = MODULE.sub(inline_pin, updated)
    updated = THIRD_PARTY.sub(
        lambda m: replace_pin(m, *third_pins[m['name']]),
        updated,
    )
    hashes = render_hashes(version, commit, pins["mediawiki"][1], {p: pins[p] for p in modules})
    return updated, hashes, version


def nix_context(root, staged):
    lock = json.loads((root / "flake.lock").read_text())
    node = lock["nodes"][lock["root"]]["inputs"]["nixpkgs"]
    locked = lock["nodes"][node]["locked"]
    source = run("nix", "eval", "--impure", "--raw", "--expr",
                 f"(builtins.fetchTree (builtins.fromJSON {nix_string(json.dumps(locked))})).outPath")
    return (f"let pkgs = import (builtins.toPath {nix_string(source)}) {{ }}; "
            f"wiki = pkgs.callPackage (builtins.toPath {nix_string(staged)}) {{ }}; in ")


def build(context, expression):
    return Path(run("nix", "build", "--impure", "--no-link", "--print-out-paths",
                    "--expr", context + expression))


def vendor_hash(context):
    expression = context + '(wiki.composerVendor.overrideAttrs { outputHash = ""; outputHashAlgo = "sha256"; })'
    drv = run("nix", "eval", "--impure", "--raw", "--expr", f"({expression}).drvPath")
    result = subprocess.run(
        ["nix", "build", "--impure", "--no-link", "--expr", expression],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    match = re.search(
        r"hash mismatch in fixed-output derivation '" + re.escape(drv)
        + r"':\s+specified:\s+\S+\s+got:\s+(sha256-[A-Za-z0-9+/]{43}=)",
        result.stderr,
    )
    if result.returncode == 0 or not match:
        log(result.stderr)
        raise UpdateError("Could not determine the Composer vendor hash; see the Nix build error above")
    return match[1]


def update_composer(context, staged, work, version, composer):
    source = build(context, "wiki.src")
    composer_work = work / "composer"
    shutil.copytree(source, composer_work, symlinks=True)
    composer_work.chmod(0o755)
    for name in ("composer.json", "composer.lock"):
        path = composer_work / name
        if path.exists():
            path.chmod(0o644)
    shutil.copyfile(staged / "composer.lock", composer_work / "composer.lock")
    env = dict(os.environ, COMPOSER_HOME=str(work / "composer-home"),
               COMPOSER_CACHE_DIR=str(work / "composer-cache"), COMPOSER_ROOT_VERSION=version)
    run(str(composer.composer / "bin/composer"), "update", "--no-dev", "--no-install", "--no-scripts", "--no-plugins",
        "--no-interaction", "--no-progress", cwd=composer_work, env=env)
    shutil.copyfile(composer_work / "composer.lock", staged / "composer.lock")
    hash_value = vendor_hash(context)
    default = staged / "default.nix"
    default.write_text(replace_one(r'vendorHash = "[^"\n]+";', f'vendorHash = "{hash_value}";', default.read_text()))
    output = build(context, "wiki")
    log(f"Validated build: {output}")


def publish(wiki, staged, original, write):
    if any((wiki / name).read_text() != original[name] for name in FILES):
        raise UpdateError("Wiki files changed during the update; refusing to overwrite concurrent edits")
    changed = {name: (staged / name).read_text() for name in FILES
               if (staged / name).read_text() != original[name]}
    for name, content in changed.items():
        path = f"packages/puyonexus/wiki/{name}"
        sys.stdout.writelines(difflib.unified_diff(original[name].splitlines(keepends=True),
                                                 content.splitlines(keepends=True),
                                                 fromfile="a/" + path, tofile="b/" + path))
    if write:
        replaced = []
        try:
            for name, content in changed.items():
                with tempfile.NamedTemporaryFile(mode="w", dir=wiki, delete=False) as handle:
                    temporary = Path(handle.name)
                    handle.write(content)
                try:
                    temporary.chmod((wiki / name).stat().st_mode & 0o777)
                    temporary.replace(wiki / name)
                    replaced.append(name)
                finally:
                    temporary.unlink(missing_ok=True)
        except BaseException:
            for name in replaced:
                (wiki / name).write_text(original[name])
            raise
    log(f"{'Updated' if write else 'Previewed'} {len(changed)} files."
        + ("" if write else " Checkout unchanged; rerun with --write to apply."))


def main(argv=None):
    parser = argparse.ArgumentParser(description="Wiki updater")
    parser.add_argument("--version", help="explicit stable patch version in the current series")
    parser.add_argument("--write", action="store_true", help="apply files only after a successful full build")
    parser.add_argument("--ref", action="append", default=[], metavar="NAME=REF",
                        help="override a third-party extension with a full Git ref or commit")
    parser.add_argument("--jobs", type=int, default=4, help="parallel archive downloads (default: 4)")
    args = parser.parse_args(argv)
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    overrides = {}
    for item in args.ref:
        name, separator, ref = item.partition("=")
        if not separator or not re.fullmatch(r"\w+", name) or not ref or name in overrides:
            parser.error("each --ref must be a unique NAME=REF")
        overrides[name] = ref
    for command in ("git", "nix"):
        if not shutil.which(command):
            parser.error(f"required command is missing: {command}")
    wiki = Path(__file__).resolve().parent
    root = wiki.parents[2]
    original = {name: (wiki / name).read_text() for name in FILES}
    with tempfile.TemporaryDirectory(prefix="puyonexus-wiki-update-") as directory:
        work = Path(directory)
        staged = work / "wiki"
        shutil.copytree(wiki, staged, ignore=shutil.ignore_patterns("__pycache__"))
        context = nix_context(root, staged)
        composer = ComposerTools(context)
        default, hashes, version = update_sources(original["default.nix"], work, args.version,
                                                  overrides, args.jobs, composer)
        (staged / "default.nix").write_text(default)
        (staged / "hashes.nix").write_text(hashes)
        update_composer(context, staged, work, version, composer)
        publish(wiki, staged, original, args.write)


if __name__ == "__main__":
    try:
        main()
    except (UpdateError, OSError, ValueError, KeyError) as error:
        log(f"Update failed: {error}")
        sys.exit(1)
    except KeyboardInterrupt:
        log("Update interrupted")
        sys.exit(130)
