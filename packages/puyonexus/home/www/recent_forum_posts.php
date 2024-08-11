<?php
/*
 * Fetches recent forum posts
 */

// Returns topics that have had recent activity
function get_recent_topics($number = 5)
{
	global $auth, $db, $phpEx;
	
	// The topic URL and last post URL
	$topic_url = '/forum/viewtopic.' . $phpEx . '?f=%s&amp;t=%s';
	$last_post_url = $topic_url . '&amp;p=%s#p%3$s';
	
	// Query the forum
	$forums = array_unique(array_keys($auth->acl_getf('f_read', true)));
	$sql = 'SELECT t.topic_id, t.forum_id, t.topic_title, t.topic_last_post_id, t.topic_last_poster_id, t.topic_last_poster_name, t.topic_last_post_time,
		f.forum_name
			FROM ' . TOPICS_TABLE . ' t, ' . FORUMS_TABLE . ' f
			WHERE ' . $db->sql_in_set('t.forum_id', $forums) . '
				AND t.topic_approved = 1
				AND f.forum_id = t.forum_id
			ORDER BY t.topic_last_post_time DESC
			LIMIT 0,' . (int)$number;
	$result = $db->sql_query($sql);
	
	// Fill the topics array
	$topics = array();
	while ($topic = $db->sql_fetchrow($result))
	{
		$topics[] = array(
			'topic_title'    => $topic['topic_title'],
			'topic_link'     => sprintf($topic_url,     $topic['forum_id'], $topic['topic_id']),
			'last_post_link' => sprintf($last_post_url, $topic['forum_id'], $topic['topic_id'], $topic['topic_last_post_id']),
		);
	}
	
	return $topics;
}

 // Get the number of posts to retrieve. Limit it to 10.
if (!isset($_GET['limit'])) die;
$number = filter_var($_GET['limit'], FILTER_VALIDATE_INT);
if ($number === false) die;
if ($number < 0 || $number > 10) die;

// File paths
define('PHPBB_ABS_PATH',     '/home/puyonexus/apps/forum/phpbb/phpBB');
define('PHPBB_PATH',         '/forum');

// Initalize phpbb session
define('IN_PHPBB', true);
define('PHPBB_ROOT_PATH', PHPBB_ABS_PATH . '/');

$phpbb_root_path = (defined('PHPBB_ROOT_PATH')) ? PHPBB_ROOT_PATH : './';
$phpEx = substr(strrchr(__FILE__, '.'), 1);
include($phpbb_root_path . 'common.' . $phpEx);

// Start session management
$user->session_begin();
$auth->acl($user->data);
$user->setup();

//echo serialize(forum_recent_topics($number));
echo json_encode(get_recent_topics($number));
