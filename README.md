Quilt
=====

Thin patterns facing CouchDB.


Getting involved
----------------

If you share my euphoria on this approach feel free to fork my Quilt and start experimenting with Rubys FuseFS API and CouchDB.


Some resources you might consider as a starting point:

* [CouchDB Project Page](http://couchdb.apache.org/)
* [Ruby FuseFS RubyForge Project Page](http://rubyforge.org/projects/fusefs/)
* [CouchDB: The Definitive Guide](http://books.couchdb.org/relax/)



Next Steps
----------

The next steps in Quilt development are

* change document root _app/_ to list all databases instead of just one configurable database
* view results under _view/_ subfolder on design documents
* list and show results under corresponding subfolders on design documents
* attachements



Installation
------------

Quilt is written in Ruby using the FuseFS Ruby Library.
To install Quilt you first need to install the following software:

    apt-get install ruby rubygems libfusefs-ruby
    apt-get install couchdb
    gem install couchrest

I hope I have not forgotten any dependency. Feel free to contact me (schmidt@netzmerk.com) if you run into any troubles.


Install Quilt
-------------

Installation of quilt is simple as cloning the project source tree from GitHub:

    git clone git://github.com/jo/quilt.git




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


