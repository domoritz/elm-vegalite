port module GalleryAdvanced exposing (elmToJS)

import Platform
import VegaLite exposing (..)



-- NOTE: All data sources in these examples originally provided at
-- https://github.com/vega/vega-datasets
-- The examples themselves reproduce those at https://vega.github.io/vega-lite/examples/


advanced1 : Spec
advanced1 =
    let
        desc =
            description "Calculation of percentage of total"

        data =
            dataFromColumns []
                << dataColumn "Activity" (strs [ "Sleeping", "Eating", "TV", "Work", "Exercise" ])
                << dataColumn "Time" (nums [ 8, 2, 4, 8, 2 ])

        trans =
            transform
                << window
                    [ ( [ wiAggregateOp opSum, wiField "Time" ], "TotalTime" ) ]
                    [ wiFrame Nothing Nothing ]
                << calculateAs "datum.Time/datum.TotalTime * 100" "PercentOfTotal"

        enc =
            encoding
                << position X [ pName "PercentOfTotal", pMType Quantitative, pAxis [ axTitle "% of total time" ] ]
                << position Y [ pName "Activity", pMType Nominal ]
    in
    toVegaLite
        [ desc, heightStep 12, data [], trans [], bar [], enc [] ]


advanced2 : Spec
advanced2 =
    let
        desc =
            description "Calculation of difference from average"

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/movies.json" []

        trans =
            transform
                << filter (fiExpr "isValid(datum.IMDB_Rating)")
                << joinAggregate [ opAs opMean "IMDB_Rating" "AverageRating" ] []
                << filter (fiExpr "(datum.IMDB_Rating - datum.AverageRating) > 2.5")

        barEnc =
            encoding
                << position X [ pName "IMDB_Rating", pMType Quantitative, pAxis [ axTitle "IMDB Rating" ] ]
                << position Y [ pName "Title", pMType Ordinal ]

        barSpec =
            asSpec [ bar [], barEnc [] ]

        ruleEnc =
            encoding
                << position X [ pName "AverageRating", pAggregate opMean, pMType Quantitative ]

        ruleSpec =
            asSpec [ rule [ maColor "red" ], ruleEnc [] ]
    in
    toVegaLite
        [ desc, data, trans [], layer [ barSpec, ruleSpec ] ]


advanced3 : Spec
advanced3 =
    let
        desc =
            description "Calculation of difference from annual average"

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/movies.json" []

        trans =
            transform
                << filter (fiExpr "isValid(datum.IMDB_Rating)")
                << timeUnitAs year "Release_Date" "year"
                << joinAggregate [ opAs opMean "IMDB_Rating" "AverageYearRating" ] [ wiGroupBy [ "year" ] ]
                << filter (fiExpr "(datum.IMDB_Rating - datum.AverageYearRating) > 2.5")

        barEnc =
            encoding
                << position X [ pName "IMDB_Rating", pMType Quantitative, pAxis [ axTitle "IMDB Rating" ] ]
                << position Y [ pName "Title", pMType Ordinal ]

        barSpec =
            asSpec [ bar [ maClip True ], barEnc [] ]

        tickEnc =
            encoding
                << position X [ pName "AverageYearRating", pMType Quantitative ]
                << position Y [ pName "Title", pMType Ordinal ]
                << color [ mStr "red" ]

        tickSpec =
            asSpec [ tick [], tickEnc [] ]
    in
    toVegaLite [ desc, data, trans [], layer [ barSpec, tickSpec ] ]


advanced4 : Spec
advanced4 =
    let
        desc =
            description "A scatterplot showing each movie in the database and the difference from the average movie rating."

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/movies.json"

        trans =
            transform
                << filter (fiExpr "isValid(datum.IMDB_Rating)")
                << filter (fiRange "Release_Date" (dtRange [] [ dtYear 2019 ]))
                << joinAggregate [ opAs opMean "IMDB_Rating" "AverageRating" ] []
                << calculateAs "datum.IMDB_Rating - datum.AverageRating" "RatingDelta"

        enc =
            encoding
                << position X [ pName "Release_Date", pMType Temporal ]
                << position Y
                    [ pName "RatingDelta"
                    , pMType Quantitative
                    , pAxis [ axTitle "Residual" ]
                    ]
    in
    toVegaLite
        [ desc
        , data []
        , trans []
        , enc []
        , point [ maStrokeWidth 0.3, maOpacity 0.3 ]
        ]


advanced5 : Spec
advanced5 =
    let
        des =
            description "Line chart showing ranks over time for thw World Cup 2018 Group F teams"

        data =
            dataFromColumns []
                << dataColumn "team" (strs [ "Germany", "Mexico", "South Korea", "Sweden", "Germany", "Mexico", "South Korea", "Sweden", "Germany", "Mexico", "South Korea", "Sweden" ])
                << dataColumn "matchday" (nums [ 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3 ])
                << dataColumn "point" (nums [ 0, 3, 0, 3, 3, 6, 0, 3, 3, 6, 3, 6 ])
                << dataColumn "diff" (nums [ -1, 1, -1, 1, 0, 2, -2, 0, -2, -1, 0, 3 ])

        trans =
            transform
                << window [ ( [ wiOp woRank ], "rank" ) ]
                    [ wiSort [ wiDescending "point", wiDescending "diff" ], wiGroupBy [ "matchday" ] ]

        enc =
            encoding
                << position X [ pName "matchday", pMType Ordinal ]
                << position Y [ pName "rank", pMType Ordinal ]
                << color [ mName "team", mMType Nominal, mScale teamColours ]

        teamColours =
            categoricalDomainMap
                [ ( "Germany", "black" )
                , ( "Mexico", "#127153" )
                , ( "South Korea", "#c91a3c" )
                , ( "Sweden", "#0c71ab" )
                ]
    in
    toVegaLite
        [ des
        , title "World Cup 2018: Group F Rankings" [ tiFrame tfBounds, tiFontStyle "italic" ]
        , data []
        , trans []
        , enc []
        , line [ maOrient moVertical ]
        ]


advanced6 : Spec
advanced6 =
    let
        des =
            description "Waterfall chart of monthly profit and loss"

        data =
            dataFromColumns []
                << dataColumn "label" (strs [ "Begin", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "End" ])
                << dataColumn "amount" (nums [ 4000, 1707, -1425, -1030, 1812, -1067, -1481, 1228, 1176, 1146, 1205, -1388, 1492, 0 ])

        trans =
            transform
                << window [ ( [ wiAggregateOp opSum, wiField "amount" ], "sum" ) ] []
                << window [ ( [ wiOp woLead, wiField "label" ], "lead" ) ] []
                << calculateAs "datum.lead === null ? datum.label : datum.lead" "lead"
                << calculateAs "datum.label === 'End' ? 0 : datum.sum - datum.amount" "previous_sum"
                << calculateAs "datum.label === 'End' ? datum.sum : datum.amount" "amount"
                << calculateAs "(datum.label !== 'Begin' && datum.label !== 'End' && datum.amount > 0 ? '+' : '') + datum.amount" "text_amount"
                << calculateAs "(datum.sum + datum.previous_sum) / 2" "center"
                << calculateAs "datum.sum < datum.previous_sum ? datum.sum : ''" "sum_dec"
                << calculateAs "datum.sum > datum.previous_sum ? datum.sum : ''" "sum_inc"

        enc =
            encoding
                << position X [ pName "label", pMType Ordinal, pSort [], pTitle "Months" ]

        enc1 =
            encoding
                << position Y [ pName "previous_sum", pMType Quantitative, pTitle "Amount" ]
                << position Y2 [ pName "sum" ]
                << color
                    [ mDataCondition
                        [ ( expr "datum.label === 'Begin' || datum.label === 'End'", [ mStr "#f7e0b6" ] )
                        , ( expr "datum.sum < datum.previous_sum", [ mStr "#f78a64" ] )
                        ]
                        [ mStr "#93c4aa" ]
                    ]

        spec1 =
            asSpec [ enc1 [], bar [ maSize 45 ] ]

        enc2 =
            encoding
                << position X2 [ pName "lead" ]
                << position Y [ pName "sum", pMType Quantitative ]

        spec2 =
            asSpec
                [ enc2 []
                , rule
                    [ maColor "#404040"
                    , maOpacity 1
                    , maStrokeWidth 2
                    , maXOffset -22.5
                    , maX2Offset 22.5
                    ]
                ]

        enc3 =
            encoding
                << position Y [ pName "sum_inc", pMType Quantitative ]
                << text [ tName "sum_inc", tMType Nominal ]

        spec3 =
            asSpec
                [ enc3 []
                , textMark
                    [ maDy -8
                    , maFontWeight Bold
                    , maColor "#404040"
                    ]
                ]

        enc4 =
            encoding
                << position Y [ pName "sum_dec", pMType Quantitative ]
                << text [ tName "sum_dec", tMType Nominal ]

        spec4 =
            asSpec
                [ enc4 []
                , textMark
                    [ maDy 8
                    , maBaseline vaTop
                    , maFontWeight Bold
                    , maColor "#404040"
                    ]
                ]

        enc5 =
            encoding
                << position Y [ pName "center", pMType Quantitative ]
                << text [ tName "text_amount", tMType Nominal ]
                << color
                    [ mDataCondition
                        [ ( expr "datum.label === 'Begin' || datum.label === 'End'"
                          , [ mStr "#725a30" ]
                          )
                        ]
                        [ mStr "white" ]
                    ]

        spec5 =
            asSpec [ enc5 [], textMark [ maBaseline vaMiddle, maFontWeight Bold ] ]
    in
    toVegaLite
        [ des
        , width 800
        , height 450
        , data []
        , trans []
        , enc []
        , layer [ spec1, spec2, spec3, spec4, spec5 ]
        ]


advanced7 : Spec
advanced7 =
    let
        des =
            description "Using the lookup transform to combine data"

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/lookup_groups.csv"

        trans =
            transform
                << lookup "person"
                    (dataFromUrl "https://vega.github.io/vega-lite/data/lookup_people.csv" [])
                    "name"
                    [ "age", "height" ]

        enc =
            encoding
                << position X [ pName "group", pMType Ordinal ]
                << position Y [ pName "age", pMType Quantitative, pAggregate opMean ]
    in
    toVegaLite [ des, data [], trans [], enc [], bar [] ]


advanced8 : Spec
advanced8 =
    let
        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/iris.json" []

        trans =
            transform
                << foldAs [ "petalWidth", "petalLength", "sepalWidth", "sepalLength" ] "measurement" "value"
                << density "value" [ dnBandwidth 0.3, dnGroupBy [ "measurement" ] ]

        enc =
            encoding
                << position X [ pName "value", pMType Quantitative, pTitle "width/length (cm)" ]
                << position Y [ pName "density", pMType Quantitative ]
                << row [ fName "measurement", fMType Nominal ]
    in
    toVegaLite [ width 300, height 50, data, trans [], enc [], area [] ]


advanced9 : Spec
advanced9 =
    let
        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/iris.json" []

        trans =
            transform
                << foldAs [ "petalWidth", "petalLength", "sepalWidth", "sepalLength" ] "measurement" "value"
                << density "value"
                    [ dnBandwidth 0.3
                    , dnGroupBy [ "measurement" ]
                    , dnExtent (num 0) (num 8)
                    , dnSteps 200
                    ]

        enc =
            encoding
                << position X [ pName "value", pMType Quantitative, pTitle "width/length (cm)" ]
                << position Y [ pName "density", pMType Quantitative ]
                << color [ mName "measurement", mMType Nominal ]
    in
    toVegaLite [ width 400, height 100, data, trans [], enc [], area [ maOpacity 0.5 ] ]


advanced10 : Spec
advanced10 =
    let
        des =
            description "Parallel coordinates plot with manual generation of parallel axes"

        cfg =
            configure
                << configuration (coView [ vicoStroke Nothing ])
                << configuration (coAxisX [ axcoDomain False, axcoLabelAngle 0, axcoTickColor "#ccc" ])
                << configuration
                    (coNamedStyles
                        [ ( "label", [ maBaseline vaMiddle, maAlign haRight, maDx -5, maTooltip ttNone ] )
                        , ( "tick", [ maOrient moHorizontal, maTooltip ttNone ] )
                        ]
                    )

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/iris.json"

        trans =
            transform
                << window [ ( [ wiAggregateOp opCount ], "index" ) ] []
                << fold [ "petalLength", "petalWidth", "sepalLength", "sepalWidth" ]
                << joinAggregate [ opAs opMin "value" "min", opAs opMax "value" "max" ] [ wiGroupBy [ "key" ] ]
                << calculateAs "(datum.value - datum.min) / (datum.max-datum.min)" "normVal"
                << calculateAs "(datum.min + datum.max) / 2" "mid"

        encLine =
            encoding
                << position X [ pName "key", pMType Nominal ]
                << position Y [ pName "normVal", pMType Quantitative, pAxis [] ]
                << color [ mName "species", mMType Nominal ]
                << detail [ dName "index", dMType Nominal ]
                << tooltips
                    [ [ tName "petalLength", tMType Quantitative ]
                    , [ tName "petalWidth", tMType Quantitative ]
                    , [ tName "sepalLength", tMType Quantitative ]
                    , [ tName "sepalWidth", tMType Quantitative ]
                    ]

        specLine =
            asSpec [ encLine [], line [ maOpacity 0.3 ] ]

        encAxis =
            encoding
                << position X [ pName "key", pMType Nominal, pAxis [ axTitle "" ] ]
                << detail [ dAggregate opCount, dMType Quantitative ]

        specAxis =
            asSpec [ encAxis [], rule [ maColor "#ccc" ] ]

        encAxisLabelsTop =
            encoding
                << position X [ pName "key", pMType Nominal ]
                << position Y [ pNum 0 ]
                << text [ tName "max", tMType Quantitative, tAggregate opMax ]

        specAxisLabelsTop =
            asSpec [ encAxisLabelsTop [], textMark [ maStyle [ "label" ] ] ]

        encAxisLabelsMid =
            encoding
                << position X [ pName "key", pMType Nominal ]
                << position Y [ pNum 150 ]
                << text [ tName "mid", tMType Quantitative, tAggregate opMin ]

        specAxisLabelsMid =
            asSpec [ encAxisLabelsMid [], textMark [ maStyle [ "label" ] ] ]

        encAxisLabelsBot =
            encoding
                << position X [ pName "key", pMType Nominal ]
                << position Y [ pHeight ]
                << text [ tName "min", tMType Quantitative, tAggregate opMin ]

        specAxisLabelsBot =
            asSpec [ encAxisLabelsBot [], textMark [ maStyle [ "label" ] ] ]
    in
    toVegaLite
        [ des
        , cfg []
        , width 600
        , height 300
        , data []
        , trans []
        , layer [ specLine, specAxis, specAxisLabelsTop, specAxisLabelsMid, specAxisLabelsBot ]
        ]


advanced11 : Spec
advanced11 =
    let
        desc =
            description "Production budget of the film with highest US Gross in each major genre."

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/movies.json"

        enc =
            encoding
                << position X
                    [ pName "Production_Budget"
                    , pMType Quantitative
                    , pAggregate (opArgMax (Just "US_Gross"))
                    ]
                << position Y [ pName "Major_Genre", pMType Nominal ]
    in
    toVegaLite [ desc, data [], enc [], bar [] ]


advanced12 : Spec
advanced12 =
    let
        desc =
            description "Plot showing average data with raw values in the background."

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/stocks.csv"

        trans =
            transform << filter (fiExpr "datum.symbol === 'GOOG'")

        encRaw =
            encoding
                << position X [ pName "date", pMType Temporal, pTimeUnit year ]
                << position Y [ pName "price", pMType Quantitative ]

        specRaw =
            asSpec [ encRaw [], point [ maOpacity 0.3 ] ]

        encAv =
            encoding
                << position X [ pName "date", pMType Temporal, pTimeUnit year ]
                << position Y [ pName "price", pAggregate opMean, pMType Quantitative ]

        specAv =
            asSpec [ encAv [], line [] ]
    in
    toVegaLite [ desc, data [], trans [], layer [ specRaw, specAv ] ]


advanced13 : Spec
advanced13 =
    let
        desc =
            description "Plot showing a 30 day rolling average with raw values in the background."

        data =
            dataFromUrl "https://vega.github.io/vega-lite/data/seattle-weather.csv"

        trans =
            transform
                << window [ ( [ wiAggregateOp opMean, wiField "temp_max" ], "rollingMean" ) ]
                    [ wiFrame (Just -15) (Just 15) ]

        encRaw =
            encoding
                << position X [ pName "date", pTitle "Date", pMType Temporal ]
                << position Y [ pName "temp_max", pTitle "Maximum temperature", pMType Quantitative ]

        specRaw =
            asSpec [ encRaw [], point [ maOpacity 0.3 ] ]

        encAv =
            encoding
                << position X [ pName "date", pMType Temporal ]
                << position Y [ pName "rollingMean", pMType Quantitative ]

        specAv =
            asSpec [ encAv [], line [ maColor "red", maSize 3 ] ]
    in
    toVegaLite [ desc, width 400, height 300, data [], trans [], layer [ specRaw, specAv ] ]



{- This list comprises the specifications to be provided to the Vega-Lite runtime. -}


mySpecs : Spec
mySpecs =
    combineSpecs
        [ ( "advanced1", advanced1 )
        , ( "advanced2", advanced2 )
        , ( "advanced3", advanced3 )
        , ( "advanced4", advanced4 )
        , ( "advanced5", advanced5 )
        , ( "advanced6", advanced6 )
        , ( "advanced7", advanced7 )
        , ( "advanced8", advanced8 )
        , ( "advanced9", advanced9 )
        , ( "advanced10", advanced10 )
        , ( "advanced11", advanced11 )
        , ( "advanced12", advanced13 )
        , ( "advanced13", advanced13 )
        ]



{- The code below is boilerplate for creating a headless Elm module that opens
   an outgoing port to Javascript and sends the specs to it.
-}


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
