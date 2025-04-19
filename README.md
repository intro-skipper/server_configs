# Why?

Jellyfin currently has no way to limit the maximum ABI version. This means that people can install incompatible versions of a plugin. Unfortunately, the error is only visible after restarting Jellyfin. The average user expects to be offered only working and compatible versions.

# Why .htaccess?

Almost all webhosters have Apache `mod_rewrite` enabled. PHP always has restrictions and is not needed anyway.
