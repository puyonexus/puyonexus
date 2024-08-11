<?php
	if (!defined('PUYONEXUS'))
	{
		exit;
	}
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="description" content="The largest English-speaking community of Puyo Puyo players and fans.">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Puyo Nexus - Home to all mean beans</title>

	<link rel="stylesheet" href="/assets/css/common.css">
	<link rel="stylesheet" href="/assets/css/home.css">
	
	<link rel="shortcut icon" href="/assets/images/favicon.ico">
	<link rel="apple-touch-icon-precomposed" href="/assets/images/apple-touch-icon-precomposed.png">

	<script>
		(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
		(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
		m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
		})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

		ga('create', 'UA-8256078-1', 'auto');
		ga('send', 'pageview');
	</script>
</head>
<body>
	<header id="pn-header">
		<nav id="pn-navbar">
			<div class="container">
				<h1 id="pn-navbar-brand">
					<a href="/">Puyo Nexus</a>
				</h1>
				<button class="pn-navbar-toggle collapsed"><span class="pn-navbar-toggle-icon" aria-hidden="true"></span></button>
				<div class="pn-navbar-collapse collapse">
					<ul class="pn-nav">
						<li><a href="/wiki/">Wiki</a></li>
						<li><a href="/forum/">Forum</a></li>
						<li><a href="/chainsim/">Chain Simulator</a></li>
					</ul>
					<ul class="pn-nav pn-nav-right pn-nav-social">
						<li><a href="https://www.facebook.com/puyonexus" target="_blank"><i class="icon icon-facebook" title="Facebook" aria-hidden="true"></i></a></li>
						<li><a href="https://twitter.com/puyonexus" target="_blank"><i class="icon icon-twitter" title="Twitter" aria-hidden="true"></i></a></li>
						<li><a href="https://www.youtube.com/user/puyonexus" target="_blank"><i class="icon icon-youtube-play" title="YouTube" aria-hidden="true"></i></a></li>
						<li><a href="https://www.twitch.tv/puyonexus" target="_blank"><i class="icon icon-twitch" title="Twitch" aria-hidden="true"></i></a></li>
						<li><a href="https://discord.gg/Br4KqbR" target="_blank"><i class="icon icon-discord" title="Discord" aria-hidden="true"></i></a></li>
					</ul>
				</div>
			</div>
		</nav>
	</header>
	<main id="content">
		<div class="container">
			<div class="row">
				<div class="col-md-9">
					<?php foreach ($news_posts as $news_post) : ?>
						<article>
							<div class="post-header">
								<ul class="post-meta">
									<li class="post-date"><?= format_news_date($news_post->post_time) ?></li>
									<li class="post-comments"><a href="<?= $news_post->topic_link ?>"><i class="icon icon-comment" aria-hidden="true"></i><?= number_format($news_post->topic_replies) ?></a></li>
								</ul>
								<h2 class="post-title"><a href="<?= $news_post->topic_link ?>"><?= $news_post->topic_title ?></a></h2>
							</div>
							<div class="post-entry"><?= $news_post->post_text ?></div>
						</article>
					<?php endforeach; ?>
					<p class="old-news"><a href="/forum/viewforum.php?f=12">View all news</a></p>
				</div>
				<div class="col-md-3 sidebar">
					<div class="slogan">
						<img src="assets/images/home/galaxy.png" alt="">
						<p>Home to all mean beans</p>
					</div>
					<section id="wiki-activity">
						<h3>Wiki Activity</h3>
						<?php if (!empty($wiki_activity) && !empty($wiki_activity->query->recentchanges)) : ?>
							<ul>
								<?php foreach ($wiki_activity->query->recentchanges as $change) : ?>
									<li>
										<span class="post-title"><a href="/wiki/<?= $change->title ?>"><?= $change->title ?></a></span>
										<ul class="post-meta">
											<li class="post-author"><a href="/wiki/User:<?= $change->user ?>"><?= $change->user ?></a></li>
											<li class="post-date"><?= format_activity_date($change->timestamp) ?></li>
										</ul>
									</li>
								<?php endforeach; ?>
							</ul>
						<?php else : ?>
							<p>No recent activity</p>
						<?php endif; ?>
					</section>
					<section>
						<h3>Links</h3>
						<ul>
							<li><a href="https://puyovs.com" target="_blank">Puyo VS</a></li>
							<li><a href="https://www.bayoen.fr/" target="_blank">Bayoen!</a></li>
							<li><a href="http://www.seganerds.com/" target="_blank">SEGA Nerds</a></li>
							<li><a href="http://segabits.com/" target="_blank">SEGAbits</a></li>
							<li><a href="https://tcrf.net/" target="_blank">The Cutting Room Floor</a></li>
							<li><a href="http://harddrop.com/" target="_blank">Hard Drop</a></li>
							<li><a href="https://tetrisconcept.net/" target="_blank">Tetrisconcept</a></li>
							<li><a href="http://michibiku.com/" target="_blank">Michibiku</a></li>
						</ul>
					</section>
				</div>
			</div>
		</div>
	</main>
	<footer id="pn-footer">
		<div class="container">
			<p>&copy; 2007-2024 Puyo Nexus</p>
		</div>
	</footer>
	
	<script src="/assets/js/common.min.js"></script>
</body>
</html>
