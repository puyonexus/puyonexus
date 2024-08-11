<?php

define('PUYONEXUS', true);

/*function get_include_contents($filename, $args) {
	ob_start();
	
	if (is_array($args))
	{
		extract($args);
	}
	
	include $filename;
	return ob_get_clean();
}*/

function format_news_date($date)
{
	$date_formatted = new \DateTime($date);
	$date_diff = (new \DateTime())->diff($date_formatted)->days;
	
	if ($date_diff === 0)
	{
		return 'Today';
	}
	else if ($date_diff === 1)
	{
		return 'Yesterday';
	}
	
	return $date_formatted->format('F j, Y');
}

function format_activity_date($date)
{
	$formats = [
		[ 'property' => 'y', 'one' => '%s year ago', 'more' => '%s years ago' ],
		[ 'property' => 'm', 'one' => '%s month ago', 'more' => '%s months ago' ],
		[ 'property' => 'w', 'one' => '%s week ago', 'more' => '%s weeks ago' ],
		[ 'property' => 'd', 'one' => '%s day ago', 'more' => '%s days ago' ],
		[ 'property' => 'h', 'one' => '%s hour ago', 'more' => '%s hours ago' ],
		[ 'property' => 'm', 'one' => '%s minute ago', 'more' => '%s minutes ago' ],
		[ 'property' => 's', 'one' => 'just now', 'more' => 'just now' ],
	];
	$formats_count = count($formats);
	
	// Get the date difference, then add weeks and fudge days
	$date_diff = (new \DateTime())->diff(new \DateTime($date));
	$date_diff->w = (int)($date_diff->d / 7);
	$date_diff->d = $date_diff->d % 7;
	
	$index = 0;
	while ($index + 1 < $formats_count && $date_diff->{$formats[$index]['property']} === 0)
	{
		$index++;
	}
		
	$date_unit = $date_diff->{$formats[$index]['property']};
	
	if ($date_unit === 1)
	{
		return sprintf($formats[$index]['one'], $date_unit);
	}
	
	return sprintf($formats[$index]['more'], $date_unit);
}

// Fetch news posts and forum activity
$news_posts = json_decode(file_get_contents('http://puyonexus.com/home/news_posts.php?limit=5'));

// Fetch wiki activity
// Mediawiki already has an api for this, so we will just call it directly
$wiki_activity = json_decode(file_get_contents('http://puyonexus.com/mediawiki/api.php?action=query&list=recentchanges&rcnamespace=0&rctype=edit|new&rcprop=title|user|timestamp&rclimit=5&rctoponly=1&format=json'));

require 'home/templates/index.php';
