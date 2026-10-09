# Benday

Benday is a year mood canvas. Home is the plate: a year of cells, today's cell magnified, and a docked tray of twelve inks.

The architecture is a bristle-lay fold. `YearMatrix` is the only model the screens observe. Each `Cell` is Open, Armed, or Laid. Dip writes an `Ink` onto the `Bristle` and folds today from Open to Armed. A sketch is one PencilKit stroke while Armed. Pen-up writes a `LayMark` and one `MoodEntry`, then folds Armed to Laid. Peel today removes that entry and returns the cell to Open. A matrix with no laid cells shows Gesso.

That fold is the product. The stroke is the persisted verb, so the year reads as brushwork instead of a score or a feed.
