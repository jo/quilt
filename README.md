Quilt
=====

Thin patterns facing CouchDB.


Important Note
--------------

This document describes how Quilt **should** work, not what it currently does.
Quilt currently only maps design documents to the app root, and no write operations are supported.

That is why I need your help. If you share my euphoria on this approach feel free to fork my Quilt and start experimenting with Rubys FuseFS API and CouchDB.


Some resources you might consider as a starting point:

* [Ruby FuseFS RubyForge Project Page](http://rubyforge.org/projects/fusefs/)
* [CouchDB Project Page](http://couchdb.apache.org/)
* [CouchDB: The Definitive Guide](http://books.couchdb.org/relax/)
* [JSON Primer](http://books.couchdb.org/relax/appendix/json-primer)


### Questions

* How to deal with temporary editor files, like .swp etc? Ruby FuseFS provides some functionality for this but I had problems saving documents with Vim as well as with Gedit. (Contact me for details)

Installation
------------

See INSTALL file.



Introduction
------------

CouchDB is a document based Database System. The documents are stored in JSON format. Documents can have so called attachements, so CouchDB can easyly store files.
CouchDB holds application code in Design Documents. These documents are normal CouchDB documents, which have the prefix *\_design/* as id, for example *\_design/Site*.
Design documents hold application code, that is views (Map-Reduce functions), show and list transformations.
Application Assets, as Images and CSS files, are stored inside design documents as attachements, too.

Quilt maps CouchDB documents to a filesystem, provided by FuseFS.
Quilt is currently using Ruby to create a Fuse Filesystem. The Filesystem is mounted to the app/ directory.

The CouchDB documents are mapped to a directory structure in the following way:

* each Document is a directory named after the id of the document. Design documents are stored in a subfolder called _design.
* each key in the hash of the document is a directory inside the documents folder
* the value of the hash lives inside the key folder
* strings are plain files with the extension .js
* floats are plain files with the extension .f
* integers are plain files with the extension .i
* arrays are directories where the elements are *all* numbered, like 000, 001 and 002.js



Example JSON Mapping
--------------------

note that the map functions are shorted for simplicity and would not work well.

### JSON CouchDB document (design document):

    {
       "_id": "_design/Site",
       "_rev": "955-e08d9e52c17159fa1c981202ae6bfcbb",
       "language": "javascript",
       "views": {
           "all": {
               "map": "function(doc) { emit(doc['_id'], 1) }"
           },
           "by_domain": {
               "map": "function(doc) { emit(doc['domain'], 1) }"
           }
       }
    }


### Corresponding Quilt filesystem mapping:

    app/
      _design/
        Site/
          _id.js       # _design/Site
          _rev.js      # 955-e08d9e52c17159fa1c981202ae6bfcbb
          language.js  # javascript
          views/
            all/
              map.js   # function(doc) { emit(doc['_id'], 1) }
            by_domain/
              map.js   # function(doc) { emit(doc['domain'], 1) }



Getting started
---------------

Change *DB_NAME* in *script/fs* to fullfit your database name.

inside the base directory run

    script/fs


Your Application code will now be available at ./app.


