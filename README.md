This project is a test for being able to create/edit large "chunk" 2D tilemaps while loading and unloading
chunks as needed.

* "Chunks" are only TileMap nodes
* Select the ChunkEditor node and draw as if on a normal TileMap
* Each chunk is currently defined as a 32x32 tile area
* When not actively drawing, the chunk in which the mouse is hovering will be fully opaque
* Dirty, but otherwise inactive chunks will have an alpha of 0.75
* Unmodified inactive chunks will have an alpha of 0.5
* "Dirty" chunks will be saved every 10 seconds as long as no drawing is taking place.
* "Dirty" chunks are *not* unloaded until they are saved regardless of how far the mouse is from the "dirty" chunk.

This test project is a rough proof of concept. Feel tree to take the idea and run with it.
Depending on desired complexity, threading the loading and saving of "chunks" may be best,
but perhaps not needed for this 2D map.

**NOTE:** While this project will run, it does nothing at runtime. This is primarily an in-editor
project. If moved to another project, be sure to add the plugin to any new project.


