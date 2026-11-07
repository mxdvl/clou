import Toybox.Graphics;
import Toybox.Lang;

//! Today's date in the middle of the dial, one column of three rows:
//!
//!   SAT
//!    7
//!   NOV
//!
//! The day of the month sits exactly on the screen's centre, in _craie_; the
//! weekday and month sit just above and below it, in _brume_.
module DateStack {

    const LABEL_FONT = Graphics.FONT_TINY;
    const NUMBER_FONT = Graphics.FONT_NUMBER_MEDIUM;
    const GAP = 4.0;  // px between the number and each label

    //! `labelHeight` and `numberHeight` are the heights of `LABEL_FONT` and
    //! `NUMBER_FONT` on this device, as the Dc reports them.
    function scene(
        layout as Layout, weekday as String, day as Number, month as String,
        labelHeight as Number, numberHeight as Number
    ) as Array<Shapes.Shape> {
        var offset = numberHeight / 2.0 + GAP + labelHeight / 2.0;
        return [
            new Shapes.Text(layout.centreX, layout.centreY - offset, weekday.toUpper(), LABEL_FONT, Palette.BRUME),
            new Shapes.Text(layout.centreX, layout.centreY, day.toString(), NUMBER_FONT, Palette.CRAIE),
            new Shapes.Text(layout.centreX, layout.centreY + offset, month.toUpper(), LABEL_FONT, Palette.BRUME),
        ] as Array<Shapes.Shape>;
    }
}
