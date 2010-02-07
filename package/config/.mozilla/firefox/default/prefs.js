# Mozilla User Preferences

/* Do not edit this file.
 *
 * If you make changes to this file while the application is running,
 * the changes will be overwritten when the application exits.
 *
 * To make a manual change to preferences, you can visit the URL about:config
 * For more information, see http://www.mozilla.org/unix/customizing.html#prefs
 */

user_pref("app.update.lastUpdateTime.addon-background-update-timer", 1012992266);
user_pref("app.update.lastUpdateTime.background-update-timer", 1012992265);
user_pref("app.update.lastUpdateTime.blocklist-background-update-timer", 1012992265);
user_pref("app.update.lastUpdateTime.microsummary-generator-update-timer", 1012992265);
user_pref("app.update.lastUpdateTime.places-maintenance-timer", 1012992282);
user_pref("app.update.lastUpdateTime.search-engine-update-timer", 1012992267);
//user_pref("browser.bookmarks.restore_default_bookmarks", false);
user_pref("browser.download.manager.showWhenStarting", false);
user_pref("browser.link.open_newwindow.restriction", 0);
user_pref("browser.migration.version", 1);
user_pref("browser.places.importBookmarksHTML", false);
//user_pref("browser.places.smartBookmarksVersion", 1); // firefox 3.5.2
user_pref("browser.places.smartBookmarksVersion", 2);
user_pref("browser.rights.3.shown", true);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.homepage_override.mstone", "rv:1.9.2");
user_pref("browser.startup.page", 0);
//user_pref("extensions.enabledItems", "{972ce4c6-7e08-4474-a285-3208198ce6fd}:3.5.3");
//user_pref("extensions.lastAppVersion", "3.5.3");
user_pref("extensions.update.notifyUser", false);
user_pref("intl.charsetmenu.browser.cache", "ISO-8859-1, UTF-8");
user_pref("network.cookie.prefsMigrated", true);
//user_pref("privacy.sanitize.migrateFx3Prefs", true);
user_pref("spellchecker.dictionary", "en-US");
//user_pref("urlclassifier.keyupdatetime.https://sb-ssl.google.com/safebrowsing/newkey", 1015584269);

// prevent firefox from upgrades
user_pref("app.update.enabled", false); 
user_pref("extensions.update.enabled", false); 
user_pref("browser.search.update", false);

// mozilla engine optimizations
user_pref("content.notify.backoffcount", 5);
user_pref("network.dns.disableIPv6", true);
user_pref("network.http.pipelining", true);
user_pref("network.http.pipelining.maxrequests", 8);
user_pref("network.http.proxy.pipelining", true);
user_pref("network.prefetch-next", false);
user_pref("nglayout.initialpaint.delay", 0);
user_pref("plugin.expose_full_path", true);
user_pref("ui.submenu.delay", 0);
user_pref("browser.cache.memory.capacity", 16384);