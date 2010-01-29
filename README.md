Quilt
=====

Read and write CouchDB documents via FUSE userspace filesystem


Install dependencies
--------------------

    apt-get install ruby rubygems libfusefs-ruby
    apt-get install couchdb
    gem install couchrest


Install Quilt
-------------

    git clone git://github.com/jo/quilt.git


Getting started
---------------

inside the Quilt directory run

    script/quilt


Your Application code will now be available at ./app/<CouchDB server url>.

You can create databases and documents with mkdir, add properties via echo >> and so on.
Databases and documents can be deleted via a touch /database_id/_delete or /database_id/document_id/_delete.


Read more on the [projectpage](http://jo.github.com/quilt/).
