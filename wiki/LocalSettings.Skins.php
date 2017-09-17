<?php
if (!defined('MEDIAWIKI')) { exit; }

# Skins
wfLoadSkin("VectorNexus");
wfLoadSkin("MonoBook");
wfLoadSkin("Modern");
wfLoadSkin("CologneBlue");
wfLoadSkin("Vector");

# Vector settings
$wgDefaultSkin = 'vectornexus';
$wgVectorUseSimpleSearch = true;
$wgDefaultUserOptions['usebetatoolbar'] = 1;
$wgDefaultUserOptions['usebetatoolbar-cgd'] = 1;
$wgDefaultUserOptions['wikieditor-preview'] = 1;
$wgDefaultUserOptions['vector-collapsiblenav'] = 1;
