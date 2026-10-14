import QtQuick
import QtQuick.Shapes
import qs.components
import qs.config

// The profile wallpaper, dimmed and darkened, under a radial vignette and a
// tiled grain. Its own layer, because a parent's opacity fade acts on the whole
// subtree at once -- see DESIGN.md. Dimmed rather than blurred: see Wallpaper.
Item {
    id: root

    layer.enabled: true

    Wallpaper {
        anchors.fill: parent
        dim: 0.58
    }

    // Radial vignette: clear in the middle, black at the corners.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"

            fillGradient: RadialGradient {
                centerX: root.width / 2
                centerY: root.height / 2
                centerRadius: Math.max(root.width, root.height) * 0.62
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.55
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0.75)
                }
            }

            startX: 0
            startY: 0
            PathLine {
                x: root.width
                y: 0
            }
            PathLine {
                x: root.width
                y: root.height
            }
            PathLine {
                x: 0
                y: root.height
            }
        }
    }

    // A 128px noise tile rather than a shader: Qt 6 wants shaders precompiled,
    // and tiling an image costs nothing.
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/grain.png")
        fillMode: Image.Tile
        opacity: 0.05
        cache: true
    }
}
