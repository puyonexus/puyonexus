<?php
// File paths
define('PHPBB_ABS_PATH',     '/home/puyonexus/apps/forum/phpbb/phpBB');
define('PHPBB_PATH',         '/forum');
define('MEDIAWIKI_ABS_PATH', '/home/puyonexus/apps/wiki/mediawiki');
define('MEDIAWIKI_PATH',     '/wiki');
define('MEDIAWIKI_LIB_PATH', '/mediawiki');

// Initalize phpbb session (doesn't work when in a function)
define('IN_PHPBB', true);
define('PHPBB_ROOT_PATH', PHPBB_ABS_PATH . '/');

$phpbb_root_path = (defined('PHPBB_ROOT_PATH')) ? PHPBB_ROOT_PATH : './';
$phpEx = substr(strrchr(__FILE__, '.'), 1);
include($phpbb_root_path . 'common.' . $phpEx);

// Start session management
$user->session_begin();
$auth->acl($user->data);
$user->setup();

// Fetches the news posts
function fetch_news_posts()
{
	$news_posts = array();
	$xml = new SimpleXMLElement('home/news.xml', null, true);
	
	foreach ($xml->children() as $post)
	{
		$news_posts[] = array(
			'title' => $post['title'],
			'date'  => $post['date'],
			'content' => $post,
		);
	}
	
	return $news_posts;
}

// Returns topics that have recent activity in them.
function forum_recent_topics($num_of_topics = 1)
{
	global $auth, $db, $phpEx;

	// Initalize topics array and then query them
	$topics  = array();
	$forums = array_unique(array_keys($auth->acl_getf('f_read', true)));
	$urls = array(
		'forum'     => '/forum/viewforum.' . $phpEx . '?f=%s',
		'topic'     => '/forum/viewtopic.' . $phpEx . '?f=%s&amp;t=%s',
		'last_post' => '/forum/viewtopic.' . $phpEx . '?f=%s&amp;t=%s&amp;p=%s#p%3$s',
		'profile'   => '/forum/memberlist.php?mode=viewprofile&amp;u=%s',
	);

	$sql = 'SELECT t.topic_id, t.forum_id, t.topic_title, t.topic_last_post_id, t.topic_last_poster_id, t.topic_last_poster_name, t.topic_last_post_time,
		f.forum_name
			FROM ' . TOPICS_TABLE . ' t, ' . FORUMS_TABLE . ' f
			WHERE ' . $db->sql_in_set('t.forum_id', $forums) . '
				AND t.topic_visibility = 1
				AND f.forum_id = t.forum_id
	            ORDER BY t.topic_last_post_time DESC
	            LIMIT 0,' . (int)$num_of_topics;
	$result = $db->sql_query($sql);
	
	// Fill the topics array
	while ($post = $db->sql_fetchrow($result))
	{
		$topics[] = array(
			'topic_id'    => $post['topic_id'],
			'forum_id'    => $post['forum_id'],
			'topic_title' => $post['topic_title'],
			'last_post'   => $post['topic_last_post_id'],
			'user_id'     => $post['topic_last_poster_id'],
			'user'        => $post['topic_last_poster_name'],
			'time'        => $post['topic_last_post_time'],
			'forum_name'  => $post['forum_name'],
			
			'topic_link'     => sprintf($urls['topic'], $post['forum_id'], $post['topic_id']),
			'last_post_link' => sprintf($urls['last_post'], $post['forum_id'], $post['topic_id'], $post['topic_last_post_id']),
			'user_link'      => sprintf($urls['profile'], $post['topic_last_poster_id']),
			'forum_link'     => sprintf($urls['forum'], $post['forum_id']),
		);
	}
	
	return $topics;
}

// Returns recent changes from the wiki
function wiki_recent_changes($num_of_changes = 1)
{
	$query = file_get_contents('http://puyonexus.com' . MEDIAWIKI_LIB_PATH . '/api.php?action=query&list=recentchanges' .
		'&rctype=edit|new&rcprop=title|ids|sizes|flags|user|timestamp&rclimit=' . (int)$num_of_changes . '&format=php');
	$data = unserialize($query);

	$urls = array(
		'article' => MEDIAWIKI_PATH . '/%s',
		'user'    => MEDIAWIKI_PATH . '/User:%s',
		'diff'    => MEDIAWIKI_LIB_PATH . '/index.php?title=%s&amp;curid=%s&amp;diff=%s&amp;oldid=%s&amp;rcid=%s',
		'hist'    => MEDIAWIKI_LIB_PATH . '/index.php?title=%s&amp;curid=%s&amp;action=history',
	);
	
	// Now place the results in a nice array
	foreach ($data['query']['recentchanges'] as $change)
	{
		$changes[] = array(
			'title'        => $change['title'],
			'article_link' => sprintf($urls['article'], $change['title']),
			'user'         => $change['user'],
			'user_link'    => sprintf($urls['user'], $change['user']),
			'time'         => strtotime($change['timestamp']),
			'type'         => $change['type'],
			'diff_link'    => sprintf($urls['diff'], $change['title'], $change['pageid'], $change['revid'], $change['old_revid'], $change['rcid']),
			'hist_link'    => sprintf($urls['hist'], $change['title'], $change['pageid']),
		);
	}
	
	return $changes;
}
