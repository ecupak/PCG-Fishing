System.print("04 + Visor")


import "xs" for Data, Render
import "xs_math" for Vec2
import "xs_tools" for ShapeBuilder

class Visor {
    construct new(width, height) {
        var screen = Vec2.new(width / 2, height / 2)

        var points = [
            Vec2.new(-screen.x, -screen.y),
            Vec2.new(-screen.x,  screen.y),
            Vec2.new( screen.x,  screen.y),
            Vec2.new( screen.x, -screen.y),
        ]        
        
        var builder = ShapeBuilder.new()

        builder.addPosition(points[0])
        builder.addTexture(0, 0)        

        builder.addPosition(points[1])
        builder.addTexture(0, 1)        

        builder.addPosition(points[2])
        builder.addTexture(1, 1)        

        builder.addPosition(points[3])
        builder.addTexture(1, 0)

        builder.addIndex(0)
        builder.addIndex(1)
        builder.addIndex(2)

        builder.addIndex(2)
        builder.addIndex(3)
        builder.addIndex(0)

        var image = Render.loadImage("[shared]/images/white.png")
        _shape = builder.build(image)
    }
    
    render(x, y, color) {         
        Render.shape(
            _shape,
            x, y, 
            0,
            1, 0,   // Scale аnd rotation
            color,  // Multiply color
            0x0     // Add color
        )
    }

    render(x, y, depth, color) {         
        Render.shape(
            _shape,
            x, y, 
            depth,
            1, 0,
            color,
            0x0
        )
    }
}


System.print("04 - Visor")