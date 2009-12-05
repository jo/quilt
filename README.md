# Quilt

Thin patterns facing CouchDB.


## Introduction

CouchDB is a document based Database System. The documents are stored in JSON format. Documents can have so called attachements, so CouchDB can easyly store files.
CouchDB holds application code in Design Documents. These documents are normal CouchDB documents, which have the prefix _design/ as id, for example _design/Site.
Design documents hold application code, that is views (Map-Reduce functions), show and list transformations.
Application Assets, as Images and CSS files, are stored inside design documents as attachements, too.

Quilt maps CouchDB documents to a filesystem, provided by FuseFS.
Quilt is currently using Ruby to create a Fuse Filesystem. The Filesystem is mounted to the app/ directory.

The CouchDB documents are mapped to a directory structure in the following way:

* each Document is a directory named after the id of the document. Design documents are stored in a subfolder called _design.
* each key in the hash of the document is a directory inside the documents folder
* the value of the hash lives inside the key folder
* strings and numbers in the document are plain files with the string / number as content
* arrays are a bit more complicated: to keep the sort order of the array each value gets a number as prefix, eg "01-tag1"


## Example JSON Mapping

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
        _id          # _design/Site
        _rev         # 955-e08d9e52c17159fa1c981202ae6bfcbb
        language     # javascript
        views/
          all/
            map.js   # function(doc) { emit(doc['_id'], 1) }
          by_domain/
            map.js   # function(doc) { emit(doc['domain'], 1) }


## Getting started

inside this directory run

  script/fs


Your Application code will now be available at ./app.


