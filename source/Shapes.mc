import Toybox.Graphics;
import Toybox.Lang;

//! Plain drawing records: what to draw, never how. The ring modules build
//! arrays of these with pure functions; `Render` is the only code that turns
//! them into pixels. Arrays are drawn in order (painter's algorithm), so a
//! black shape later in the list cuts a gap in whatever came before it.
module Shapes {

    typedef Shape as Arc or Line or Dot or Text;

    //! Arc on the circle of `radius` about (`centreX`, `centreY`), from `start`
    //! clockwise for `sweep`. Both are fractions of a turn from 12 o'clock;
    //! a sweep of 1 or more is a full circle.
    class Arc {
        public var centreX as Float;
        public var centreY as Float;
        public var radius as Float;
        public var start as Float;
        public var sweep as Float;
        public var color as Graphics.ColorType;
        public var penWidth as Float;

        function initialize(
            centreX as Float, centreY as Float, radius as Float,
            start as Float, sweep as Float,
            color as Graphics.ColorType, penWidth as Float
        ) {
            self.centreX = centreX;
            self.centreY = centreY;
            self.radius = radius;
            self.start = start;
            self.sweep = sweep;
            self.color = color;
            self.penWidth = penWidth;
        }
    }

    //! Straight stroke between two screen points.
    class Line {
        public var fromX as Float;
        public var fromY as Float;
        public var toX as Float;
        public var toY as Float;
        public var color as Graphics.ColorType;
        public var penWidth as Float;

        function initialize(
            fromX as Float, fromY as Float, toX as Float, toY as Float,
            color as Graphics.ColorType, penWidth as Float
        ) {
            self.fromX = fromX;
            self.fromY = fromY;
            self.toX = toX;
            self.toY = toY;
            self.color = color;
            self.penWidth = penWidth;
        }
    }

    //! Filled circle.
    class Dot {
        public var centreX as Float;
        public var centreY as Float;
        public var radius as Float;
        public var color as Graphics.ColorType;

        function initialize(centreX as Float, centreY as Float, radius as Float, color as Graphics.ColorType) {
            self.centreX = centreX;
            self.centreY = centreY;
            self.radius = radius;
            self.color = color;
        }
    }

    //! A line of text centred on (`centreX`, `centreY`), both ways.
    class Text {
        public var centreX as Float;
        public var centreY as Float;
        public var text as String;
        public var font as Graphics.FontType;
        public var color as Graphics.ColorType;

        function initialize(
            centreX as Float, centreY as Float, text as String,
            font as Graphics.FontType, color as Graphics.ColorType
        ) {
            self.centreX = centreX;
            self.centreY = centreY;
            self.text = text;
            self.font = font;
            self.color = color;
        }
    }
}
