<?php

$wgHooks['ParserFirstCallInit'][] = 'PuyoChain::onParserInit';

class PuyoChain {
	// Hook our callback function into the parser
	public static function onParserInit(Parser $parser) {
		// When the parser sees the <sample> tag, it executes
		// the wfSampleRender function (see below)
		$parser->setHook('puyochain', 'PuyoChain::render');
		// Always return true from this function. The return value does not denote
		// success or otherwise have meaning - it just must always be true.
		return true;
	}

	// Execute
	public static function render($input, array $args, Parser $parser, PPFrame $frame) {
		$w=6; $h=12;
		if (isset($args['w'])) {
			$w = $args['w'];
		}
		if (isset($args['h'])) {
			$h = $args['h'];
		}
		return '<a href="http://www.puyonexus.com/chainsim/?w=' . $w . '&h=' . $h . '&chain=' . htmlspecialchars($input) . '" title="Click to load this chain in the chain simulator."><img src="http://www.puyonexus.com/chainsim/chainimage.php?w=' . $w . '&h=' . $h . '&chain=' . htmlspecialchars($input) . '" alt="Chain" /></a>';
	}
}
