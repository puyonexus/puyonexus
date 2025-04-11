<?php

use MediaWiki\MediaWikiServices;

$wgHooks['ParserFirstCallInit'][] = 'ScaledImage::onParserInit';

class ScaledImage {
	public static function onParserInit(Parser $parser) {
		$parser->setHook('scaledimage', 'ScaledImage::render');
		return true;
	}

	public static function render($input, array $args, Parser $parser, PPFrame $frame) {
		$fileTitle = "";
		if (isset($args['file'])) {
			$fileTitle = $parser->recursiveTagParse($args['file'], $frame);
		}
		$w = 100;
		if (isset($args['width'])) {
			$w = intval($args['width']);
		}
		$h = 100;
		if (isset($args['height'])) {
			$h = intval($args['height']);
		}
		$file = MediaWikiServices::getInstance()->getRepoGroup()->findFile($fileTitle);
		if ($file == null) {
			return '<i>Image not found: ' . htmlspecialchars($fileTitle) . '</i>';
		}
		$width = $file->getWidth();
		if ($width == false) {
			$width = $w . "%";
		} else {
			$width = ($width * $w) / 100;
		}
		$height = $file->getHeight();
		if ($height == false) {
			$height = $h . "%";
		} else {
			$height = ($height * $h) / 100;
		}
		$url = $file->getFullUrl();
		$linkUrl = $url;
		$title = $file->getTitle();
		if ($title != null) {
			$linkUrl = $title->getLinkURL();
			$parserOutput = $parser->getOutput();
			$parserOutput->addImage($title->getDBkey());
			$parserOutput->addLink($title);
		}
		return '<a href="' . htmlspecialchars($linkUrl) . '"><img src="' . htmlspecialchars($url) . '" width="' . $width . '" height="' . $height . '" /></img></a>';
	}
}
