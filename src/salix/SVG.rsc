@license{
  Copyright (c) Tijs van der Storm <Centrum Wiskunde & Informatica>.
  All rights reserved.
  This file is licensed under the BSD 2-Clause License, which accompanies this project
  and is available under https://opensource.org/licenses/BSD-2-Clause.
}
@contributor{Tijs van der Storm - storm@cwi.nl - CWI}

module salix::SVG

import salix::Node;
import salix::Core;
import salix::HTML;

data Msg;

void svgBuild(list[value] vals, str tagName)
  = build([prop("namespace", "http://www.w3.org/2000/svg")] + vals, tagName); 

// User functions

void foreignObject(value vals...) = svgBuild(vals, "foreignObject");

void svg(value vals...) = svgBuild(vals, "svg");
void animate(value vals...) = svgBuild(vals, "animate");
void animateColor(value vals...) = svgBuild(vals, "animateColor");
void animateMotion(value vals...) = svgBuild(vals, "animateMotion"); 
void animateTransform(value vals...) = svgBuild(vals, "animateTransform");
void mpath(value vals...) = svgBuild(vals, "mpath");
void \set(value vals...) = svgBuild(vals, "set");

// Container elements

void a(value vals...) = svgBuild(vals, "a");
void defs(value vals...) = svgBuild(vals, "defs");
void g(value vals...) = svgBuild(vals, "g");
void marker(value vals...) = svgBuild(vals, "marker");
void maskEl(value vals...) = svgBuild(vals, "mask");
void pattern(value vals...) = svgBuild(vals, "pattern");
void \switch(value vals...) = svgBuild(vals, "switch");
void symbol(value vals...) = svgBuild(vals, "symbol");

// Descriptive elements

void desc(value vals...) = svgBuild(vals, "desc");
void metadata(value vals...) = svgBuild(vals, "metadata");
void titleEl(value vals...) = svgBuild(vals, "title");

// Filter primitive elements

void feBlend(value vals...) = svgBuild(vals, "feBlend");
void feColorMatrix(value vals...) = svgBuild(vals, "feColorMatrix");
void feComponentTransfer(value vals...) = svgBuild(vals, "feComponentTransfer");
void feComposite(value vals...) = svgBuild(vals, "feComposite");
void feConvolveMatrix(value vals...) = svgBuild(vals, "feConvolveMatrix");
void feDiffuseLighting(value vals...) = svgBuild(vals, "feDiffuseLighting");
void feDisplacementMap(value vals...) = svgBuild(vals, "feDisplacementMap");
void feFlood(value vals...) = svgBuild(vals, "feFlood");
void feFuncA(value vals...) = svgBuild(vals, "feFuncA");
void feFuncB(value vals...) = svgBuild(vals, "feFuncB");
void feFuncG(value vals...) = svgBuild(vals, "feFuncG");
void feFuncR(value vals...) = svgBuild(vals, "feFuncR");
void feGaussianBlur(value vals...) = svgBuild(vals, "feGaussianBlur");
void feImage(value vals...) = svgBuild(vals, "feImage");
void feMerge(value vals...) = svgBuild(vals, "feMerge");
void feMergeNode(value vals...) = svgBuild(vals, "feMergeNode");
void feMorphology(value vals...) = svgBuild(vals, "feMorphology");
void feOffset(value vals...) = svgBuild(vals, "feOffset");
void feSpecularLighting(value vals...) = svgBuild(vals, "feSpecularLighting");
void feTile(value vals...) = svgBuild(vals, "feTile");
void feTurbulence(value vals...) = svgBuild(vals, "feTurbulence");


// Font elements

void font(value vals...) = svgBuild(vals, "font");


// Gradient elements

void linearGradient(value vals...) = svgBuild(vals, "linearGradient");
void radialGradient(value vals...) = svgBuild(vals, "radialGradient");
void stop(value vals...) = svgBuild(vals, "stop");


// Graphics elements

void circle(value vals...) = svgBuild(vals, "circle");
void ellipse(value vals...) = svgBuild(vals, "ellipse");
void image(value vals...) = svgBuild(vals, "image");
void line(value vals...) = svgBuild(vals, "line");
void pathEl(value vals...) = svgBuild(vals, "path");
void polygon(value vals...) = svgBuild(vals, "polygon");

void polyline(value vals...) = svgBuild(vals, "polyline");
void rect(value vals...) = svgBuild(vals, "rect");
void use(value vals...) = svgBuild(vals, "use");


// Light source elements

void feDistantLight(value vals...) = svgBuild(vals, "feDistantLight");
void fePointLight(value vals...) = svgBuild(vals, "fePointLight");
void feSpotLight(value vals...) = svgBuild(vals, "feSpotLight");

// Text content elements

void altGlyph(value vals...) = svgBuild(vals, "altGlyph");
void altGlyphDef(value vals...) = svgBuild(vals, "altGlyphDef");
void altGlyphItem(value vals...) = svgBuild(vals, "altGlyphItem");
void glyph(value vals...) = svgBuild(vals, "glyph");
void glyphRefEl(value vals...) = svgBuild(vals, "glyphRef");
void textPath(value vals...) = svgBuild(vals, "textPath");
void text_(value vals...) = svgBuild(vals, "text");
void tref(value vals...) = svgBuild(vals, "tref");
void tspan(value vals...) = svgBuild(vals, "tspan");

// Uncategorized elements

void clipPathEl(value vals...) = svgBuild(vals, "clipPath");
void colorProfileEl(value vals...) = svgBuild(vals, "colorProfile");
void cursorEl(value vals...) = svgBuild(vals, "cursor");
void \filterEl(value vals...) = svgBuild(vals, "filter");
void script(value vals...) = svgBuild(vals, "script");
//void style(value vals...) = svgBuild(vals, "style");
void view(value vals...) = svgBuild(vals, "view");
  

// Attributes

Attr accentHeight(str val) = attr("accent-height", val);
Attr accelerate(str val) = attr("accelerate", val);
Attr accumulate(str val) = attr("accumulate", val);
Attr additive(str val) = attr("additive", val);
Attr alphabetic(str val) = attr("alphabetic", val);
Attr allowReorder(str val) = attr("allowReorder", val);
Attr amplitude(str val) = attr("amplitude", val);
Attr arabicForm(str val) = attr("arabic-form", val);
Attr ascent(str val) = attr("ascent", val);
Attr attributeName(str val) = attr("attributeName", val);
Attr attributeType(str val) = attr("attributeType", val);
Attr autoReverse(str val) = attr("autoReverse", val);
Attr azimuth(str val) = attr("azimuth", val);
Attr baseFrequency(str val) = attr("baseFrequency", val);
Attr baseProfile(str val) = attr("baseProfile", val);
Attr bbox(str val) = attr("bbox", val);
Attr begin(str val) = attr("begin", val);
Attr bias(str val) = attr("bias", val);
Attr by(str val) = attr("by", val);
Attr calcMode(str val) = attr("calcMode", val);
Attr capHeight(str val) = attr("cap-height", val);
Attr class(str val) = attr("class", val);
Attr clipPathUnits(str val) = attr("clipPathUnits", val);
Attr contentScriptType(str val) = attr("contentScriptType", val);
Attr contentStyleType(str val) = attr("contentStyleType", val);
Attr cx(str val) = attr("cx", val);
Attr cy(str val) = attr("cy", val);
Attr d(str val) = attr("d", val);
Attr decelerate(str val) = attr("decelerate", val);
Attr descent(str val) = attr("descent", val);
Attr diffuseConstant(str val) = attr("diffuseConstant", val);
Attr divisor(str val) = attr("divisor", val);
Attr dur(str val) = attr("dur", val);
Attr dx(str val) = attr("dx", val);
Attr dy(str val) = attr("dy", val);
Attr edgeMode(str val) = attr("edgeMode", val);
Attr elevation(str val) = attr("elevation", val);
Attr end(str val) = attr("end", val);
Attr exponent(str val) = attr("exponent", val);
Attr externalResourcesRequired(str val) = attr("externalResourcesRequired", val);
Attr filterRes(str val) = attr("filterRes", val);
Attr filterUnits(str val) = attr("filterUnits", val);
Attr format(str val) = attr("format", val);
Attr from(str val) = attr("from", val);
Attr fx(str val) = attr("fx", val);
Attr fy(str val) = attr("fy", val);
Attr g1(str val) = attr("g1", val);
Attr g2(str val) = attr("g2", val);
Attr glyphName(str val) = attr("glyph-name", val);
Attr glyphRef(str val) = attr("glyphRef", val);
Attr gradientTransform(str val) = attr("gradientTransform", val);
Attr gradientUnits(str val) = attr("gradientUnits", val);
Attr hanging(str val) = attr("hanging", val);
Attr height(str val) = attr("height", val);
Attr horizAdvX(str val) = attr("horiz-adv-x", val);
Attr horizOriginX(str val) = attr("horiz-origin-x", val);
Attr horizOriginY(str val) = attr("horiz-origin-y", val);
Attr id(str val) = attr("id", val);
Attr ideographic(str val) = attr("ideographic", val);
Attr in_(str val) = attr("in", val);
Attr in2(str val) = attr("in2", val);
Attr intercept(str val) = attr("intercept", val);
Attr k(str val) = attr("k", val);
Attr k1(str val) = attr("k1", val);
Attr k2(str val) = attr("k2", val);
Attr k3(str val) = attr("k3", val);
Attr k4(str val) = attr("k4", val);
Attr kernelMatrix(str val) = attr("kernelMatrix", val);
Attr kernelUnitLength(str val) = attr("kernelUnitLength", val);
Attr keyPoints(str val) = attr("keyPoints", val);
Attr keySplines(str val) = attr("keySplines", val);
Attr keyTimes(str val) = attr("keyTimes", val);
Attr lang(str val) = attr("lang", val);
Attr lengthAdjust(str val) = attr("lengthAdjust", val);
Attr limitingConeAngle(str val) = attr("limitingConeAngle", val);
Attr local(str val) = attr("local", val);
Attr markerHeight(str val) = attr("markerHeight", val);
Attr markerUnits(str val) = attr("markerUnits", val);
Attr markerWidth(str val) = attr("markerWidth", val);
Attr maskContentUnits(str val) = attr("maskContentUnits", val);
Attr maskUnits(str val) = attr("maskUnits", val);
Attr mathematical(str val) = attr("mathematical", val);
Attr max(str val) = attr("max", val);
Attr media(str val) = attr("media", val);
Attr method(str val) = attr("method", val);
Attr min(str val) = attr("min", val);
Attr mode(str val) = attr("mode", val);
Attr name(str val) = attr("name", val);
Attr numOctaves(str val) = attr("numOctaves", val);
Attr offset(str val) = attr("offset", val);
Attr operator(str val) = attr("operator", val);
Attr order(str val) = attr("order", val);
Attr orient(str val) = attr("orient", val);
Attr orientation(str val) = attr("orientation", val);
Attr origin(str val) = attr("origin", val);
Attr overlinePosition(str val) = attr("overline-position", val);
Attr overlineThickness(str val) = attr("overline-thickness", val);
Attr panose1(str val) = attr("panose-1", val);
Attr path(str val) = attr("path", val);
Attr pathLength(str val) = attr("pathLength", val);
Attr patternContentUnits(str val) = attr("patternContentUnits", val);
Attr patternTransform(str val) = attr("patternTransform", val);
Attr patternUnits(str val) = attr("patternUnits", val);
Attr pointOrder(str val) = attr("point-order", val);
Attr points(str val) = attr("points", val);
Attr pointsAtX(str val) = attr("pointsAtX", val);
Attr pointsAtY(str val) = attr("pointsAtY", val);
Attr pointsAtZ(str val) = attr("pointsAtZ", val);
Attr preserveAlpha(str val) = attr("preserveAlpha", val);
Attr preserveAspectRatio(str val) = attr("preserveAspectRatio", val);
Attr primitiveUnits(str val) = attr("primitiveUnits", val);
Attr r(str val) = attr("r", val);
Attr radius(str val) = attr("radius", val);
Attr refX(str val) = attr("refX", val);
Attr refY(str val) = attr("refY", val);
Attr renderingIntent(str val) = attr("rendering-intent", val);
Attr repeatCount(str val) = attr("repeatCount", val);
Attr repeatDur(str val) = attr("repeatDur", val);
Attr requiredExtensions(str val) = attr("requiredExtensions", val);
Attr requiredFeatures(str val) = attr("requiredFeatures", val);
Attr restart(str val) = attr("restart", val);
Attr result(str val) = attr("result", val);
Attr rotate(str val) = attr("rotate", val);
Attr rx(str val) = attr("rx", val);
Attr ry(str val) = attr("ry", val);
Attr scale(str val) = attr("scale", val);
Attr seed(str val) = attr("seed", val);
Attr slope(str val) = attr("slope", val);
Attr spacing(str val) = attr("spacing", val);
Attr specularConstant(str val) = attr("specularConstant", val);
Attr specularExponent(str val) = attr("specularExponent", val);
Attr speed(str val) = attr("speed", val);
Attr spreadMethod(str val) = attr("spreadMethod", val);
Attr startOffset(str val) = attr("startOffset", val);
Attr stdDeviation(str val) = attr("stdDeviation", val);
Attr stemh(str val) = attr("stemh", val);
Attr stemv(str val) = attr("stemv", val);
Attr stitchTiles(str val) = attr("stitchTiles", val);
Attr strikethroughPosition(str val) = attr("strikethrough-position", val);
Attr strikethroughThickness(str val) = attr("strikethrough-thickness", val);
Attr string(str val) = attr("string", val);
Attr style(str val) = attr("style", val);
Attr surfaceScale(str val) = attr("surfaceScale", val);
Attr systemLanguage(str val) = attr("systemLanguage", val);
Attr tableValues(str val) = attr("tableValues", val);
Attr target(str val) = attr("target", val);
Attr targetX(str val) = attr("targetX", val);
Attr targetY(str val) = attr("targetY", val);
Attr textLength(str val) = attr("textLength", val);
Attr title(str val) = attr("title", val);
Attr to(str val) = attr("to", val);
Attr transform(str val) = attr("transform", val);
Attr type_(str val) = attr("type", val);
Attr u1(str val) = attr("u1", val);
Attr u2(str val) = attr("u2", val);
Attr underlinePosition(str val) = attr("underline-position", val);
Attr underlineThickness(str val) = attr("underline-thickness", val);
Attr unicode(str val) = attr("unicode", val);
Attr unicodeRange(str val) = attr("unicode-range", val);
Attr unitsPerEm(str val) = attr("units-per-em", val);
Attr vAlphabetic(str val) = attr("v-alphabetic", val);
Attr vHanging(str val) = attr("v-hanging", val);
Attr vIdeographic(str val) = attr("v-ideographic", val);
Attr vMathematical(str val) = attr("v-mathematical", val);
Attr values(str val) = attr("values", val);
Attr version(str val) = attr("version", val);
Attr vertAdvY(str val) = attr("vert-adv-y", val);
Attr vertOriginX(str val) = attr("vert-origin-x", val);
Attr vertOriginY(str val) = attr("vert-origin-y", val);
Attr viewBox(str val) = attr("viewBox", val);
Attr viewTarget(str val) = attr("viewTarget", val);
Attr width(str val) = attr("width", val);
Attr widths(str val) = attr("widths", val);
Attr x(str val) = attr("x", val);
Attr xHeight(str val) = attr("x-height", val);
Attr x1(str val) = attr("x1", val);
Attr x2(str val) = attr("x2", val);
Attr xChannelSelector(str val) = attr("xChannelSelector", val);
//Attr xlinkActuate(str val) = attributeNS("http://www.w3.org/1999/xlink", "xlink:actuate", val);
//Attr xlinkArcrole(str val) = attrNS("http://www.w3.org/1999/xlink", "xlink:arcrole", val);
//Attr xlinkHref(str val) = attrNS("http://www.w3.org/1999/xlink", "xlink:href", val);
//Attr xlinkRole(str val) = attrNS("http://www.w3.org/1999/xlink", "xlink:role", val);
//Attr xlinkShow(str val) = attrNS("http://www.w3.org/1999/xlink", "xlink:show", val);
//Attr xlinkTitle(str val) = attrNS("http://www.w3.org/1999/xlink", "xlink:title", val);
//Attr xlinkType(str val) = attrNS("http://www.w3.org/1999/xlink", "xlink:type", val);
//Attr xmlBase(str val) = attrNS("http://www.w3.org/XML/1998/namespace", "xml:base", val);
//Attr xmlLang(str val) = attrNS("http://www.w3.org/XML/1998/namespace", "xml:lang", val);
//Attr xmlSpace(str val) = attrNS("http://www.w3.org/XML/1998/namespace", "xml:space", val);Attr y(str val) = attr("y", val);
Attr y1(str val) = attr("y1", val);
Attr y2(str val) = attr("y2", val);
Attr yChannelSelector(str val) = attr("yChannelSelector", val);
Attr z(str val) = attr("z", val);
Attr zoomAndPan(str val) = attr("zoomAndPan", val);

// Presentation attributes
Attr alignmentBaseline(str val) = attr("alignment-baseline", val);
Attr baselineShift(str val) = attr("baseline-shift", val);
Attr clipPath(str val) = attr("clip-path", val);
Attr clipRule(str val) = attr("clip-rule", val);
Attr clip(str val) = attr("clip", val);
Attr colorInterpolationFilters(str val) = attr("color-interpolation-filters", val);
Attr colorInterpolation(str val) = attr("color-interpolation", val);
Attr colorProfile(str val) = attr("color-profile", val);
Attr colorRendering(str val) = attr("color-rendering", val);
Attr color(str val) = attr("color", val);
Attr cursor(str val) = attr("cursor", val);
Attr direction(str val) = attr("direction", val);
Attr display(str val) = attr("display", val);
Attr dominantBaseline(str val) = attr("dominant-baseline", val);
Attr enableBackground(str val) = attr("enable-background", val);
Attr fillOpacity(str val) = attr("fill-opacity", val);
Attr fillRule(str val) = attr("fill-rule", val);
Attr fill(str val) = attr("fill", val);
Attr \filter(str val) = attr("filter", val);Attr floodColor(str val) = attr("flood-color", val);
Attr floodOpacity(str val) = attr("flood-opacity", val);
Attr fontFamily(str val) = attr("font-family", val);
Attr fontSizeAdjust(str val) = attr("font-size-adjust", val);
Attr fontSize(str val) = attr("font-size", val);
Attr fontStretch(str val) = attr("font-stretch", val);
Attr fontStyle(str val) = attr("font-style", val);
Attr fontVariant(str val) = attr("font-variant", val);
Attr fontWeight(str val) = attr("font-weight", val);
Attr glyphOrientationHorizontal(str val) = attr("glyph-orientation-horizontal", val);
Attr glyphOrientationVertical(str val) = attr("glyph-orientation-vertical", val);
Attr imageRendering(str val) = attr("image-rendering", val);
Attr kerning(str val) = attr("kerning", val);
Attr letterSpacing(str val) = attr("letter-spacing", val);
Attr lightingColor(str val) = attr("lighting-color", val);
Attr markerEnd(str val) = attr("marker-end", val);
Attr markerMid(str val) = attr("marker-mid", val);
Attr markerStart(str val) = attr("marker-start", val);
Attr mask(str val) = attr("mask", val);
Attr opacity(str val) = attr("opacity", val);
Attr overflow(str val) = attr("overflow", val);
Attr pointerEvents(str val) = attr("pointer-events", val);
Attr shapeRendering(str val) = attr("shape-rendering", val);
Attr stopColor(str val) = attr("stop-color", val);
Attr stopOpacity(str val) = attr("stop-opacity", val);
Attr strokeDasharray(str val) = attr("stroke-dasharray", val);
Attr strokeDashoffset(str val) = attr("stroke-dashoffset", val);
Attr strokeLinecap(str val) = attr("stroke-linecap", val);
Attr strokeLinejoin(str val) = attr("stroke-linejoin", val);
Attr strokeMiterlimit(str val) = attr("stroke-miterlimit", val);
Attr strokeOpacity(str val) = attr("stroke-opacity", val);
Attr strokeWidth(str val) = attr("stroke-width", val);
Attr stroke(str val) = attr("stroke", val);
Attr textAnchor(str val) = attr("text-anchor", val);
Attr textDecoration(str val) = attr("text-decoration", val);
Attr textRendering(str val) = attr("text-rendering", val);
Attr unicodeBidi(str val) = attr("unicode-bidi", val);
Attr visibility(str val) = attr("visibility", val);
Attr wordSpacing(str val) = attr("word-spacing", val);
Attr writingMode(str val) = attr("writing-mode", val);

// Events

Attr simpleOn(str name, Msg msg) = event(name, succeed(msg));

// ANIMATION

Attr onBegin(Msg msg) = simpleOn("begin", msg);
Attr onEnd(Msg msg) = simpleOn("end", msg);
Attr onRepeat(Msg msg) = simpleOn("repeat", msg);

// DOCUMENT

Attr onAbort(Msg msg) = simpleOn("abort", msg);
Attr onError(Msg msg) = simpleOn("error", msg);
Attr onResize(Msg msg) = simpleOn("resize", msg);
Attr onScroll(Msg msg) = simpleOn("scroll", msg);
Attr onLoad(Msg msg) = simpleOn("load", msg);
Attr onUnload(Msg msg) = simpleOn("unload", msg);
Attr onZoom(Msg msg) = simpleOn("zoom", msg);

// GRAPHICAL
// See salix::HTML for more event handler functions
Attr onActivate(Msg msg) = simpleOn("activate", msg);
Attr onFocusIn(Msg msg) = simpleOn("focusin", msg);
Attr onFocusOut(Msg msg) = simpleOn("focusout", msg);
Attr onMouseMove(Msg msg) = simpleOn("mousemove", msg);
