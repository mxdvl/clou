import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The only code that draws: turns a scene (an array of `Shapes`) into pixels,
//! in order, on a cleared black screen.
module Render {

    function draw(dc as Graphics.Dc, scene as Array<Shapes.Shape>) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Palette.CRAIE, Palette.ENCRE);
        dc.clear();

        for (var index = 0; index < scene.size(); index++) {
            var shape = scene[index];
            if (shape instanceof Shapes.Arc) {
                drawArc(dc, shape as Shapes.Arc);
            } else if (shape instanceof Shapes.Line) {
                var line = shape as Shapes.Line;
                dc.setColor(line.color, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(line.penWidth);
                dc.drawLine(line.fromX, line.fromY, line.toX, line.toY);
            } else if (shape instanceof Shapes.Dot) {
                var dot = shape as Shapes.Dot;
                dc.setColor(dot.color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dot.centreX, dot.centreY, dot.radius);
            } else if (shape instanceof Shapes.Text) {
                var text = shape as Shapes.Text;
                dc.setColor(text.color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    text.centreX, text.centreY, text.font, text.text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
    }

    //! Draws one arc, handling two cases the Dc's own arc call can't: a
    //! `sweep` of a full turn or more draws as a circle, and a sweep under
    //! half a degree is skipped rather than drawn as a stray pixel.
    function drawArc(dc as Graphics.Dc, arc as Shapes.Arc) as Void {
        dc.setColor(arc.color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(arc.penWidth);
        if (arc.sweep >= 1.0) {
            dc.drawCircle(arc.centreX, arc.centreY, arc.radius);
            return;
        }
        if (arc.sweep * 360.0 < 0.5) {
            return;
        }
        dc.drawArc(
            arc.centreX, arc.centreY, arc.radius, Graphics.ARC_CLOCKWISE,
            degrees(arc.start), degrees(arc.start + arc.sweep)
        );
    }

    //! A fraction of a turn clockwise from 12 o'clock, as the Dc's angle:
    //! whole degrees counter-clockwise from 3 o'clock, in [0, 360). Rounded
    //! here rather than left for the Dc to truncate.
    function degrees(fraction as Float) as Number {
        var angle = Math.round(90.0 - fraction * 360.0).toNumber();
        return ((angle % 360) + 360) % 360;
    }
}
