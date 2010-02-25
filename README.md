Quilt
=====

Read and write CouchDB documents via FUSE userspace filesystem


Install dependencies
--------------------

    apt-get install ruby rubygems libfusefs-ruby


Install Quilt
-------------

    gem install couch-quilt


Getting started
---------------

start quilt by typing

    couchquilt mountpoint [server] [--debug]


Your mapped CouchDB will now be available at *mountpoint*.

You can create databases and documents with mkdir, add properties via echo >> and so on.
Databases and documents can be deleted via a touch /database_id/_delete or /database_id/document_id/_delete.


Read more on the [projectpage](http://jo.github.com/quilt/).
