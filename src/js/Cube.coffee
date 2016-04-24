define ()->
    class Cube extends THREE.Mesh
        constructor: (a,b,c)->
            geometry = new THREE.BoxGeometry a,b,c
            material = new THREE.MeshBasicMaterial {color: 0x55ff00}
            super geometry, material
            return
    return Cube
