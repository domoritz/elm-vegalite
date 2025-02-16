# An elm-vegaLite Walkthrough

This walkthrough will introduce you to the principles and coding style for using elm-vegaLite to create interactive visualizations in the [Elm](http://elm-lang.org) language.
It is based on the talk given by [Wongsuphasawat et al at the 2017 Open Vis Conf](https://youtu.be/9uaHRWj04D4).
If you wish to follow along with their talk, timings are given by each section.

## A Grammar of Graphics (0:30)

_elm-vegaLite_ is a wrapper for the [Vega-Lite visualization grammar](https://vega.github.io) which itself is based on Leland Wilkinson's [Grammar of Graphics](http://www.springer.com/gb/book/9780387245447).
The grammar provides an expressive way to define how data are represented graphically.
The seven key elements of the grammar as represented in elm-vegaLite and Vega-Lite are:

- **Data**: The input to visualize. _Example elm-vegaLite functions:_ `dataFromUrl`, `dataFromColumns` and `dataFromRows`.
- **Transform**: Functions to change the data before they are visualized. _Example elm-vegaLite functions:_ `filter`, `calculateAs` and `binAs`.
- **Projection**: The mapping of 3d global geospatial locations onto a 2d plane . _Example elm-vegaLite function:_ `projection`.
- **Mark**: The visual symbol(s) that represent the data. _Example elm-vegaLite functions:_ `line`, `circle`, `bar`, `textMark` and `geoshape`.
- **Encoding**: The specification of which data elements are mapped to which mark characteristics (commonly known as _channels_). _Example elm-vegaLite functions:_ `position`, `shape`, `size` and `color`.
- **Scale**: Descriptions of the way encoded marks represent the data. _Example elm-vegaLite functions:_ `scDomain`, `scPadding` and `scInterpolate`.
- **Guides**: Supplementary visual elements that support interpreting the visualization. _Example elm-vegaLite functions:_ `axDomain` (for position encodings) and `leTitle` (for legend color, size and shape encodings).

In common with other languages that build upon a grammar of graphics such as D3 and Vega, this grammar allows fine grain control of visualization design.
But unlike those languages, Vega-Lite and elm-vegaLite provide practical default specifications for most of the grammar, allowing for a much more compact high-level form of expression.

## A Single View specification (3:03)

Let's start with a simple table of data representing time-stamped weather data for Seattle:

| date       | precipitation | temp_max | temp_min | wind | weather |
| ---------- | ------------- | -------- | -------- | ---- | ------- |
| 2012/01/01 | 0.0           | 12.8     | 5.0      | 4.7  | drizzle |
| 2012/01/02 | 10.9          | 10.6     | 2.8      | 4.5  | rain    |
| 2012/01/03 | 0.8           | 11.7     | 7.2      | 2.3  | rain    |
| ...        | ...           | ...      | ...      | ...  | ...     |

### A Strip plot (3:26)

We could encode one of the numeric data fields as a _strip plot_ where the horizontal position of a tick mark is determined by the magnitude of the data item (maximum daily temperature in this case):

![Strip plot of Seattle daily maximum temperature](images/stripPlot.png)

With elm-vegaLite, we do the following to create this visualization expression:

```elm
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , tick []
    , encoding (position X [ pName "temp_max", pQuant ] [])
    ]
```

Notice how there is no explicit definition of the axis details, color choice or size.
These can be customised, but the default values are designed to follow good practice in visualization design.

The function `toVegaLite` takes a list of grammar specifications and creates a single JSON object that encodes the entire design.
This can be sent to the Vega-Lite runtime to generate the Canvas or SVG output.

Three grammar elements are represented by the three functions `dataFromUrl`, `mark` and `encoding`.

The `encoding` function takes as a single parameter, a list of specifications that are themselves generated by other functions.
In this case we use the function `position` to provide an encoding of the `temp_max` field as the x-position in our plot.
The precise way in which temperature is mapped to the x-position will depend on the type of data we are encoding.
We can provide a hint by delcaring the _measurement type_ of the data field, here `Quantitative` indicating a numeric measurement type.
The final parameter of `position` is a list of any additional encodings in our specification.
Here, with only one encoding, we provide an empty list.

As we build up more complex visualizations we will use many more encodings. To keep the coding clear, the idiomatic way to do this with elm-vegaLite is to chain encoding functions using point-free style.
The example above coded in this way would be

```elm
let
    enc =
        encoding << position X [ pName "temp_max", pQuant ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , tick []
    , enc []
    ]
```

### Simple Histogram (5:02)

While the strip plot shows the range of temperatures, it is hard to see how many days have which temperatures. To see that, we need to show the distribution more explicitly. We can do this by _binning_ the temperatures and then aggregating the data in each bin into counts. If we encode those counts by the y-position and change our mark from _tick_ to _bar_ we have our frequency histogram:

![Histogram of Seattle daily maximum temperature](images/histogram1.png)

```elm
let
    enc =
        encoding
            << position X [ pName "temp_max", pQuant, pBin [] ]
            << position Y [ pAggregate opCount, pQuant ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , bar []
    , enc []
    ]
```

The code now contains two chained `position` encodings: one for the x-position, which is now binned, and one for the y-position which is aggregated by providing `pAggregate Count` instead of a data field name.

Notice again that sensible defaults are provided for the parts of the specification we didn't specify such as axis titles, colors and number of bins.

### Stacked Histogram (7:03)

Position isn't the only channel we can use to encode data.
Color is an important channel in many visualizations, so we can use it here to encode the dominant weather type for each date in our table.
The overall shape of the histogram is the same, but now can get some idea of the separate distributions for each of the recorded weather types.

![Stacked histogram of Seattle daily maximum temperature grouped by dominant weather type](images/histogram2.png)

```elm
let
    enc =
        encoding
            << position X [ pName "temp_max", pQuant, pBin [] ]
            << position Y [ pAggregate opCount, pQuant ]
            << color [ mName "weather", mNominal ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , bar []
    , enc []
    ]
```

The code to do this simply adds another channel encoding, this time `color` rather than `position`, and uses it to encode the `weather` data field.
Unlike temperature, weather type is _nominal_, that is, categorical with no intrinsic order.
And once again, simply by declaring the measurement type, Vega-Lite determines an appropriate color scheme and legend.

Specifications are assembled through functions prefixed with letters indicating the type of function.
So the name of the data field use to encode _position_ is specified with `pName`, its measurement type with `pQuant` and its positional aggregation with `pAggregate`, whereas the name of the data field for encoding color is indicated by `mName` and its measurement type `mMType` (where `m` is short for _mark_).

### Stacked Histogram with Customised Colors (7:20)

While the default nominal color scheme is well chosen for general purposes, we might want to customise the colors to better match the semantics of the data.

Changing the way a channel is encoded involves specifying the _scale_ and in particular the mapping between the _domain_ (the elements of the data to show) and the color _range_ used to represent them.

![Stacked histogram of Seattle daily maximum temperature grouped by dominant weather type and semantically meaningful colors](images/histogram3.png)

```elm
let
    weatherColors =
        categoricalDomainMap
            [ ( "sun", "#e7ba52" )
            , ( "fog", "#c7c7c7" )
            , ( "drizzle", "#aec7ea" )
            , ( "rain", "#1f77b4" )
            , ( "snow", "#9467bd" )
            ]

    enc =
        encoding
            << position X [ pName "temp_max", pQuant, pBin [] ]
            << position Y [ pAggregate opCount, pQuant ]
            << color [ mName "weather", mNominal, mScale weatherColors ]
    in
    toVegaLite
        [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
        , bar []
        , enc []
        ]
```

The mapping between the values in the domain (weather types `sun`, `fog` etc.) and the colors used to represent them (hex values `#e7ba52`, `#c7c7c7` etc.) is handled by an elm-vegaLite function `categoricalDomainMap` which accepts a list of tuples defining those mappings.

Notice how we never needed to state explicitly that we wished our bars to be stacked.
This was reasoned directly by Vega-Lite based on the combination of bar marks and color channel encoding.
If we were to change just the mark function from `bar` to `line`, Vega-Lite produces an unstacked series of lines, which makes sense because unlike bars, lines do not occlude one another to the same extent.

![Unstacked distributions of Seattle daily maximum temperature grouped by dominant weather type](images/lineChart.png)

```elm
let
    enc =
        encoding
            << position X [ pName "temp_max", pQuant, pBin [] ]
            << position Y [ pAggregate opCount, pQuant ]
            << color [ mName "weather", mNominal, mScale weatherColors ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , line []
    , enc []
    ]
```

The stacked bar chart version is better at showing the overall distribution of all weather types but it is more difficult to compare distributions of anything other than sun as all other weather types lack a common baseline.
To compare distributions of all categories we can move from a single view to a multi-view composition.

## Layered and Multi-view Composition (8:28)

To show our weather distributions next to each other rather than stacked on top of each other, we simply encode column position in a row of small multiples to the `weather` data field:

![Small multiples of temperature distributions by weather type](images/multiBar.png)

```elm
let
    enc =
        encoding
            << position X [ pName "temp_max", pQuant, pBin [] ]
            << position Y [ pAggregate opCount, pQuant ]
            << color [ mName "weather", mNominal, mLegend [], mScale weatherColors ]
            << column [ fName "weather", fNominal ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , bar []
    , enc []
    ]
```

There are only two additions in order to create these small multiples.
Firstly we have an extra encoding with the `column` function specifying the `weather` data field as the one to determine which column each data item gets mapped to.
Note that the `f` prefix for `fName` and `fMType` refers to _facet_ – a form of data selection and grouping standard in data visualization.

The second, minor change, is to include an `mLegend` specification in the color encoding. The legend can be customised with its parametmer list but here by providing an empty list, we declare we do not wish the default legend to appear (the arrangement into columns with color encoding and default column labels make the legend redundant).

### Multi-view Composition Operators (9:00)

There are four ways in which multiple views may be combined:

- The **facet operator** takes subsets of a dataset (facets) and separately applies the same view specification to each of those facets (as seen with the `column` function above).
  elm-vegaLite functions to create faceted views: `column`, `row`, `facet` and `specification`.

- The **layer operator** creates different views of the data but each is layered (superposed) on the same same space, for example a trend line layered on top of a scatterplot.
  elm-vegaLite functions to create a layered view: `layer` and `asSpec`.

- The **concatenation operator** allows arbitrary views (potentially with different datasets) to be assembled in rows or columns.
  This allows 'dashboards' to be built.
  elm-vegaLite functions to create concatenated views: `vConcat`, `hConcat` and `asSpec`.

- The **repeat operator** is a concise way of combining multiple views with only small data-driven differences in each view.
  elm-vegaLite functions for repeated views: `repeat` and `specification`.

## Composition Example: Precipitation in Seattle (9:40)

As a basis for discussing view composition, let's start with a single bar chart showing monthly precipitation in Seattle:

![Seattle precipitation aggregated by month](images/barChart.png)

```elm
let
    enc =
        encoding
            << position X [ pName "date", pOrdinal, pTimeUnit month ]
            << position Y [ pName "precipitation", pQuant, pAggregate opMean ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , bar []
    , enc []
    ]
```

(Note that here we've cast the date, which has been quantized into monthly intervals, to be ordinal so that bars span the full width of each month.)

### Composing layers (10:08)

We can annotate the chart by placing the bar chart specification in a _layer_ and adding another layer with the annotation.
In this example we will add a layer showing the average precipitation for the entire period:

![Seattle precipitation aggregated by month with average line as separate layer](images/barChart2.png)

```elm
let
    precipEnc =
        encoding << position Y [ pName "precipitation", pQuant, pAggregate opMean ]

    barEnc =
        encoding << position X [ pName "date", pOrdinal, pTimeUnit month ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , precipEnc []
    , layer [ asSpec [ bar [], barEnc [] ], asSpec [ rule [] ] ]
    ]
```

The bar encoding is as it was previously, but this time instead of passing it directly to `toVegaLite` we store it in its own specification object with `asSpec`.
We add a similar average line specification but only need to encode the y-position as we wish to span the entire chart space with the `rule` mark.
The two specifications are combined as layers with the `layer` function which we add to the list of specifications passed to `toVegaLite` in place of the original bar specification.
Note also how we can extract the encoding common to both (as `precipEnc`) so the y position encoding only needs to be specified once.

### Concatenating views (10:47)

Instead of layering one view on top of another (superposition), we can place them side by side in a row or column (juxtaposition). In Vega-Lite this is referred to as _concatenation_:

![Seattle precipitation and maximum temperatures](images/barChartPair.png)

```elm
let
    bar1Enc =
        encoding
            << position X [ pName "date", pOrdinal, pTimeUnit month ]
            << position Y [ pName "precipitation", pQuant, pAggregate opMean ]

    bar2Enc =
        encoding
            << position X [ pName "date", pOrdinal, pTimeUnit month ]
            << position Y [ pName "temp_max", pQuant, pAggregate opMean ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , vConcat [ asSpec [ bar [], bar1Enc [] ], asSpec [ bar [], bar2Enc [] ] ]
    ]
```

Concatenated views are specified in the same way as layered views expect that we use the `vConcat` function (or `hConcat` for a horizontal arrangement) in place of `layer`.

### Repeated Views (11:08)

Noting that juxtaposing similar charts is a common operation, and the specification for each of them often is very similar, the repeat operator allows us to streamline the specification required to do this.
We might, for example, wish to show three data fields from the Seattle weather dataset:

![Seattle precipitation, temperatures and wind speed](images/barChartTriplet.png)

```elm
let
    enc =
        encoding
            << position X [ pName "date", pOrdinal, pTimeUnit month ]
            << position Y [ pRepeat arRow, pQuant, pAggregate opMean ]

    spec =
        asSpec
            [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
            , bar []
            , enc []
            ]
in
toVegaLite
    [ repeat [ rowFields [ "precipitation", "temp_max", "wind" ] ]
    , specification spec
    ]
```

This more compact specification replaces the data field name (`pName "precipitation"` etc.) with a reference to the repeating field (`pRepeat`) either as a `Row` or `Column` depending on the desired layout. We then compose the specifications by providing a set of `rowFields` (or `columnFields`) containing a list of the fields to which we wish to apply the specification (identified with the function `specification` which should follow the `repeat` function provided to `toVegaLite`).

We can combine repeated rows and repeated columns to create a grid of views, such as a scatterplot matrix (or SPLOM for short):

![Scatterplot matrix comparing wind, temperature and precipitation](images/splom.png)

```elm
let
    enc =
        encoding
            << position X [ pRepeat arColumn, pQuant ]
            << position Y [ pRepeat arRow, pQuant ]

    spec =
        asSpec
            [ dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
            , point []
            , enc []
            ]
in
toVegaLite
    [ repeat
        [ rowFields [ "temp_max", "precipitation", "wind" ]
        , columnFields [ "wind", "precipitation", "temp_max" ]
        ]
    , specification spec
    ]
```

### Building A Dashboard (12:40)

We can compose more complex 'dashboards' by assembling single views but varying either their encoding or the data that is encoded. To illustrate, let's first identify the four single view types that we will compose with (all of these we have considered above, but are shown here again for clarity).

![Four single views](images/dashboard1.png)

As we have seen, we can arrange combinations of these views with the composition operators _layer_, _facet_, _repeat_ and _concatenate_. The specifications that result can themselves be further composed with the same operators to form a tree of compositions:

![Composition tree](images/compositionTree.png)

This allows us to create a nested dashboard of views:

![Full dashboard of 17 views of Seattle weather](images/dashboard2.png)

```elm
let
    histoEnc =
        encoding
            << position X [ pName "temp_max", pQuant, pBin [] ]
            << position Y [ pAggregate opCount, pQuant ]
            << color [ mName "weather", mNominal, mLegend [], mScale weatherColors ]
            << column [ fName "weather", fNominal ]

    histoSpec =
        asSpec [ bar [], histoEnc [] ]

    scatterEnc =
        encoding
            << position X [ pRepeat arColumn, pQuant ]
            << position Y [ pRepeat arRow, pQuant ]

    scatterSpec =
        asSpec [ point [], scatterEnc [] ]

    barEnc =
        encoding
            << position X [ pName "date", pOrdinal, pTimeUnit month ]
            << position Y [ pRepeat arRow, pQuant, pAggregate opMean ]

    annotationEnc =
        encoding
            << position Y [ pRepeat arRow, pQuant, pAggregate opMean ]

    layerSpec =
        asSpec
            [ layer
                [ asSpec [ bar [], barEnc [] ]
                , asSpec [ rule [], annotationEnc [] ]
                ]
            ]

    barsSpec =
        asSpec
            [ repeat [ rowFields [ "precipitation", "temp_max", "wind" ] ]
            , specification layerSpec
            ]

    splomSpec =
        asSpec
            [ repeat
                [ rowFields [ "temp_max", "precipitation", "wind" ]
                , columnFields [ "wind", "precipitation", "temp_max" ]
                ]
            , specification scatterSpec
            ]
in
toVegaLite
    [ --  dataFromUrl "https://vega.github.io/vega-lite/data/newYork-weather.csv" []
      dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv" []
    , vConcat
        [ asSpec [ hConcat [ splomSpec, barsSpec ] ]
        , histoSpec
        ]
    ]
```

There is nothing new in this example – we have simply assembled a range of views with the composition operators.
It is worth noting that the data source (`seattle-weather.csv`) need only be identified once so can be removed from the component view specifications.
This has the advantage that if we were to replace the reference to the data file with another, we only need do it once.
Here, for example is exactly the same specification but with `newYork-weather` given as the data source.

![Full dashboard of 17 views of New York weather](images/dashboard2NY.png)

It would be trivial to concatenate these two specifications to allow a Seattle – New York comparison dashboard to be created.

## Interaction (14:35)

Interaction is enabled by creating _selections_ that may be combined with the kinds of specifications already described.
Selections involve three components:

- **Events** are those actions that trigger the interaction such as clicking at a location on screen or pressing a key.

- **Points of interest** are the elements of the visualization with which the interaction occurs, for example, a set of points selected on a scatterplot.

- **Predicates** (i.e. Boolean functions) identify whether or not something is included in the selection. These need not be limited to only those parts of the visualization directly selected through interaction (see _selection projection_ below).

By way of an example consider this colored scatterplot where any point can be selected and all non-selected points are turned grey (_see [examples/walkthrough.html](../../examples/walkthrough.html) for the interactive version of the visualization; below a click is symbolised by the highlighting circle._):

![Single mark selection on a scatterplot](images/interactiveScatter1.png)

```elm
let
    enc =
        encoding
            << position X [ pName "Horsepower", pQuant ]
            << position Y [ pName "Miles_per_Gallon", pQuant ]
            << color
                [ mSelectionCondition (selectionName "picked")
                    [ mName "Origin", mNominal ]
                    [ mStr "grey" ]
                ]

    sel =
        selection
            << select "picked" seSingle []
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/cars.json" []
    , circle []
    , enc []
    , sel []
    ]
```

In comparison to the static specifications we have already seen, the addition here is the new function `selection` that is added to the spec passed to Vega-Lite and a new `mSelectionCondition` used to encode color.

Previously when encoding color (or any other channel) we have provided a list of properties.
Here we provide a pair of lists – one for when the selection condition is true, the other for when it is false.

The name `"picked"` is just one we have chosen to call the selection.
The type of selection here generated by `seSingle` meaning we can only select one item at a time.

Because we will reuse the scatterplot specification in several examples, we can declare the basic specification in its own Elm function:

```elm
scatterProps : List ( VLProperty, Spec )
scatterProps =
    let
        enc =
            encoding
                << position X [ pName "Horsepower", pQuant ]
                << position Y [ pName "Miles_per_Gallon", pQuant ]
                << color
                    [ mSelectionCondition (selectionName "picked")
                        [ mName "Origin", mNominal ]
                        [ mStr "grey" ]
                    ]
    in
    [ dataFromUrl "https://vega.github.io/vega-lite/data/cars.json" []
    , trans []
    , circle []
    , enc []
    ]
```

This allows us to add the selection specification separately.
So the previous example can now be created by adding the selection function and passing the complete list to `toVegaLite`

```elm
let
    sel =
        selection
            << select "picked" seSingle []
in
toVegaLite (sel [] :: scatterProps)
```

To select multiple points by shift-clicking, we use `seMulti` instead of 'seSingle' in the `selection`:

![Multi-point selection on a scatterplot](images/interactiveScatter2.png)

```elm
let
    sel =
        selection
            << select "picked" seMulti []
in
toVegaLite (sel [] :: scatterProps)
```

Alternatively, we could make the selection happen based on any browser event by parameterising `select` with the function `seOn` and a value matching a JavaScript event name, such as mouse movement over points to give more of a paintbrush effect:

![Multi-point selection on a scatterplot with mouse hover](images/interactiveScatter3.png)

```elm
let
    sel =
        selection
            << select "picked" seMulti [ seOn "mouseover" ]
in
toVegaLite (sel [] :: scatterProps)
```

### Selection Transformations (16:39)

Simple selections as described above create sets of selected data marks based directly on what was interacted with by the user.
Selection transformations allow us to _project_ that direct selection onto other parts of our dataset.
For example, suppose we wanted to know what effect the number of engine cylinders has on the relationship between engine power and engine efficiency.
We can invoke a _selection projection_ on `Cylinders` in our dataset that says 'when a single point is selected, extend that selection to all other points in the dataset that share the same number of cylinders':

![Selection projection onto marks with matched number of cylinders](images/interactiveScatter4.png)

```elm
let
    sel =
        selection
            << select "picked" seSingle [ seEmpty, seFields [ "Cylinders" ] ]
in
toVegaLite (sel [] :: scatterProps)
```

This is invoked simply by adding an `seFields` function to the `select` parameters naming the fields onto which we wish to project our selection.
Additionally, we have set the default selection with `seEmpty` here so that if nothing is selected, the selection is empty (without this the default selection is the entire encoded dataset.)

Selection need not be limited to direct interaction with the visualization marks.
We can also _bind_ the selection to other user-interface components.
For example we could select all those cars with a chosen number of cylinders with a slider by binding the selection to an HTML _input range_ component.
Clicking on a point projects the selection as before, but also updates the slider; moving the slider updates the selected points:

![Selecton bound to slider representing number of engine cylinders](images/interactiveScatter5.png)

```elm
let
    sel =
        selection
            << select "picked"
                seSingle
                [ seFields [ "Cylinders" ]
                , seBind [ iRange "Cylinders" [ inMin 3, inMax 8, inStep 1 ] ]
                ]
in
toVegaLite (sel [] :: scatterProps)
```

The binding to the slider is added with the `seBind` function followed by a function representing the HTML input element (`iRange` in this example), the data field to which it is to be bound and then a list of optional input element parameters (here just setting the limits of the slider and step between slider values).
The binding is two-way, so directly selecting points on the scatterplot updates the sliders and moving the sliders updates the selected (and therefore highlighted) points.

Binding need not be limited to single input element.
We could, for example, bind another input slider to the year of manufacture to see if there are any trends in engine efficiency over time.
Here the selection projection matches both number of cylinders and year of manufacture either selected by clicking on a mark or adjusting the sliders:

![Selection bound to sliders representing year of manufacture and number of engine cylinders](images/interactiveScatter6.png)

```elm
let
    sel =
        selection
            << select "picked"
                seSingle
                [ seFields [ "Cylinders", "Year" ]
                , seBind
                    [ iRange "Cylinders" [ inMin 3, inMax 8, inStep 1 ]
                    , iRange "Year" [ inMin 1969, inMax 1981, inStep 1 ]
                    ]
                ]
in
toVegaLite (sel [] :: scatterProps)
```

The `seInterval` selection function is useful for rapidly choosing a region of a view.
Simply providing an unparameterised selection allows both the width and the height of the selection to be chosen:

![Interval selection in X- and Y- dimensions](images/interactiveScatter7.png)

```elm
let
    sel =
        selection
            << select "picked" seInterval []
in
toVegaLite (sel [] :: scatterProps)
```

Projecting the selection onto a position channel can be used to select all marks that have an X- or Y- position within a region regardless of the other spatial coordinate:

![Interval selection projected onto X-coordinates of selected marks](images/interactiveScatter8.png)

```elm
let
    sel =
        selection
            << select "picked" seInterval [ seEncodings [ chX ] ]
in
toVegaLite (sel [] :: scatterProps)
```

Notice here that to project the selection we parameterise the `selext` not with a field name as we have done previously but with a channel encoding using the function `seEncodings` (here parameterised with the X-position channel function `chX`).

If we further _bind_ that selection to the _scale_ transformation of X-position, we have created the ability to pan and zoom the view as the scaling is determined interactively depending on the extent and position of the interval selection:

![Selection bound to scale of scatterplot](images/interactiveScatter9.png)

```elm
let
    sel =
        selection
            << select "picked" seInterval [ seEncodings [ chX ], seBindScales ]
in
toVegaLite (sel [] :: scatterProps)
```

### Multiple Coordinated Views (19:38)

One of the more powerful aspects of selection-based interaction is in coordinating different views – a selection of a data subset is projected onto all other views of the same data:

![Selection across views](images/coordinatedScatter1.png)

```elm
let
    enc =
        encoding
            << position X [ pRepeat arColumn, pQuant ]
            << position Y [ pRepeat arRow, pQuant ]
            << color
                [ mSelectionCondition (selectionName "picked")
                    [ mName "Origin", mNominal ]
                    [ mStr "grey" ]
                ]

    sel =
        selection
            << select "picked" seInterval [ seEncodings [ chX ] ]

    spec =
        asSpec
            [ dataFromUrl "https://vega.github.io/vega-lite/data/cars.json" []
            , circle []
            , enc []
            , sel []
            ]
in
toVegaLite
    [ repeat
        [ rowFields [ "Displacement", "Miles_per_Gallon" ]
        , columnFields [ "Horsepower", "Miles_per_Gallon" ]
        ]
    , specification spec
    ]
```

There is nothing new in the specification here other than combining the `repeat` function with the `selection`.
The selection is projected across all views as it is duplicated by the `repeat` operator.

It is a simple step to bind the scales of the scatterplots in the same way to coordinate zooming and panning across views:

![Selection across views](images/coordinatedScatter2.png)

```elm
let
    enc =
        encoding
            << position X [ pRepeat arColumn, pQuant ]
            << position Y [ pRepeat arRow, pQuant ]
            << color [ mName "Origin", mNominal ]

    sel =
        selection
            << select "picked" seInterval [ seBindScales ]

    spec =
        asSpec
            [ dataFromUrl "https://vega.github.io/vega-lite/data/cars.json" []
            , circle []
            , enc []
            , sel []
            ]
in
toVegaLite
    [ repeat
        [ rowFields [ "Displacement", "Miles_per_Gallon" ]
        , columnFields [ "Horsepower", "Miles_per_Gallon" ]
        ]
    , specification spec
    ]
```

The only difference between this and the previous example is that we now use `seBindScales` based on the selection rather than provide a conditional encoding of color.

The ability to determine the scale of a chart based on a selection is useful in implementing a common visualization design pattern, that of 'context and focus' (or sometimes referred to as 'overview and detail on demand').
We can achieve this by setting the scale of one view based on the selection in another.
The detail view is updated whenever the selected region is changed through interaction:

![Selection across views](images/contextAndFocus.png)

```elm
let
    sel =
        selection << select "brush" seInterval [ seEncodings [ chX ] ]

    encContext =
        encoding
            << position X [ pName "date", pTemporal, pAxis [ axFormat "%Y" ] ]
            << position Y
                [ pName "price"
                , pQuant
                , pAxis [ axTickCount 3, axGrid False ]
                ]

    specContext =
        asSpec [ width 400, height 80, sel [], area [], encContext [] ]

    encDetail =
        encoding
            << position X
                [ pName "date"
                , pTemporal
                , pScale [ scDomain (doSelection "brush") ]
                , pAxis [ axTitle "" ]
                ]
            << position Y [ pName "price", pQuant ]

    specDetail =
        asSpec [ width 400, area [], encDetail [] ]
in
toVegaLite
    [ dataFromUrl "https://vega.github.io/vega-lite/data/sp500.csv" []
    , vConcat [ specContext, specDetail ]
    ]
```

### Cross-filtering (20:41)

The final example brings together ideas of view composition and interactive selection with data filtering by implementing _cross-filtering_.

A cross-filter involves selecting a subset of the data in one view and then only displaying those data in other views.
In this example we use `repeat` to show three fields in a flights database – hour of day in which a flight departs, the distribution of flight delays and the distribution of flight distances. By selecting a subset of any one of those views, we overlay a layer in a gold color of just those selected flights for all three fields:

![Cross filtering](images/crossFilter.png)

```elm
let
    hourTrans =
        -- This generates a new field based on the hour of day extracted from the date field.
        transform
            << calculateAs "hours(datum.date)" "hour"

    sel =
        selection << select "brush" seInterval [ seEncodings [ chX ] ]

    filterTrans =
        transform
            << filter (fiSelection "brush")

    totalEnc =
        encoding
            << position X [ pRepeat arColumn, pQuant ]
            << position Y [ pAggregate opCount, pQuant ]

    selectedEnc =
        encoding
            << position X [ pRepeat arColumn, pQuant ]
            << position Y [ pAggregate opCount, pQuant ]
            << color [ mStr "goldenrod" ]
in
toVegaLite
    [ repeat [ columnFields [ "hour", "delay", "distance" ] ]
    , specification <|
        asSpec
            [ dataFromUrl "https://vega.github.io/vega-lite/data/flights-2k.json"
                [ parse [ ( "date", foDate "%Y/%m/%d %H:%M" ) ] ]
            , hourTrans []
            , layer
                [ asSpec [ bar [], totalEnc [] ]
                , asSpec [ sel [], filterTrans [], bar [], selectedEnc [] ]
                ]
            ]
    ]
```
