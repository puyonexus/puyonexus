<?php
if (!defined('MEDIAWIKI')) { exit; }

# Extensions
wfLoadExtension("ConfirmEdit");
wfLoadExtension('ConfirmEdit/QuestyCaptcha');
wfLoadExtension("PuyoChain");
wfLoadExtension("Cite");
wfLoadExtension("Gadgets");
wfLoadExtension("ImageMap");
wfLoadExtension("InputBox");
wfLoadExtension("Nuke");
wfLoadExtension("ParserFunctions");
wfLoadExtension("Poem");
wfLoadExtension("WikiEditor");
wfLoadExtension("EmbedVideo");
wfLoadExtension("Renameuser");
wfLoadExtension("Math");
wfLoadExtension("SyntaxHighlight_GeSHi");
wfLoadExtension("SpamBlacklist");
wfLoadExtension("CheckUser");
wfLoadExtension("Moderation");
wfLoadExtension("AbuseFilter");

# Setup CAPTCHA extension
$wgCaptchaClass = 'QuestyCaptcha';
$wgCaptchaQuestions[] = array(
    'question' => 'What is the name (in English) of the protagonist\'s pet/sidekick in the video game Puyo Puyo?',
    'answer' => 'Carbuncle'
);
