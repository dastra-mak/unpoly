###**
Utility functions
=================
  
Unpoly comes with a number of utility functions
that might save you from loading something like [Lodash](https://lodash.com/).

@class up.util
###
up.util = (($) ->

  ###**
  A function that does nothing.

  @function up.util.noop
  @experimental
  ###
  noop = (->)

  ###**
  A function that returns a resolved promise.

  @function up.util.asyncNoop
  @internal
  ###
  asyncNoop = -> Promise.resolve()

  ###**
  Ensures that the given function can only be called a single time.
  Subsequent calls will return the return value of the first call.

  Note that this is a simple implementation that
  doesn't distinguish between argument lists.

  @function up.util.memoize
  @internal
  ###
  memoize = (func) ->
    cachedValue = undefined
    cached = false
    (args...) ->
      if cached
        cachedValue
      else
        cached = true
        cachedValue = func(args...)

  ###**
  Returns if the given port is the default port for the given protocol.

  @function up.util.isStandardPort
  @internal
  ###  
  isStandardPort = (protocol, port) ->
    port = port.toString()
    ((port == "" || port == "80") && protocol == 'http:') || (port == "443" && protocol == 'https:')

  ###**
  Normalizes relative paths and absolute paths to a full URL
  that can be checked for equality with other normalized URLs.
  
  By default hashes are ignored, search queries are included.
  
  @function up.util.normalizeUrl
  @param {boolean} [options.hash=false]
    Whether to include an `#hash` anchor in the normalized URL
  @param {boolean} [options.search=true]
    Whether to include a `?query` string in the normalized URL
  @param {boolean} [options.stripTrailingSlash=false]
    Whether to strip a trailing slash from the pathname
  @internal
  ###
  normalizeUrl = (urlOrAnchor, options) ->
    parts = parseUrl(urlOrAnchor)
    normalized = parts.protocol + "//" + parts.hostname
    normalized += ":#{parts.port}" unless isStandardPort(parts.protocol, parts.port)
    pathname = parts.pathname
    # Some IEs don't include a leading slash in the #pathname property.
    # We have seen this in IE11 and W3Schools claims it happens in IE9 or earlier
    # http://www.w3schools.com/jsref/prop_anchor_pathname.asp
    pathname = "/#{pathname}" unless pathname[0] == '/'
    pathname = pathname.replace(/\/$/, '') if options?.stripTrailingSlash == true
    normalized += pathname
    normalized += parts.hash if options?.hash == true
    normalized += parts.search unless options?.search == false
    normalized

  isCrossDomain = (targetUrl) ->
    currentUrl = parseUrl(location.href)
    targetUrl = parseUrl(targetUrl)
    currentUrl.protocol != targetUrl.protocol || currentUrl.host != targetUrl.host

  ###**
  Parses the given URL into components such as hostname and path.

  If the given URL is not fully qualified, it is assumed to be relative
  to the current page.

  @function up.util.parseUrl
  @return {Object}
    The parsed URL as an object with
    `protocol`, `hostname`, `port`, `pathname`, `search` and `hash`
    properties.
  @experimental
  ###
  parseUrl = (urlOrAnchor) ->
    # In case someone passed us a $link, unwrap it
    if isJQuery(urlOrAnchor)
      urlOrAnchor = getElement(urlOrAnchor)

    # If we are handed a parsed URL, just return it
    if urlOrAnchor.pathname
      return urlOrAnchor

    anchor = $('<a>').attr(href: urlOrAnchor).get(0)
    # In IE11 the #hostname and #port properties of such a link are empty
    # strings. However, we can fix this by assigning the anchor its own
    # href because computer:
    # https://gist.github.com/jlong/2428561#comment-1461205
    anchor.href = anchor.href if isBlank(anchor.hostname)
    anchor

  ###**
  @function up.util.normalizeMethod
  @internal
  ###
  normalizeMethod = (method) ->
    if method
      method.toUpperCase()
    else
      'GET'

  ###**
  @function up.util.methodAllowsPayload
  @internal
  ###
  methodAllowsPayload = (method) ->
    method != 'GET' && method != 'HEAD'

  ###**
  @function $createElementFromSelector
  @internal
  ###
  $createElementFromSelector = (selector) ->
    path = selector.split(/[ >]/)
    $root = null
    for depthSelector, iteration in path
      conjunction = depthSelector.match(/(^|\.|\#)[A-Za-z0-9\-_]+/g)
      tag = "div"
      classes = []
      id = null
      for expression in conjunction
        switch expression[0]
          when "."
            classes.push expression.substr(1)
          when "#"
            id = expression.substr(1)
          else
            tag = expression
      html = "<" + tag
      html += " class=\"" + classes.join(" ") + "\""  if classes.length
      html += " id=\"" + id + "\""  if id
      html += ">"
      $element = $(html)
      $element.appendTo($parent) if $parent
      $root = $element if iteration == 0
      $parent = $element
    $root

  ###**
  @function $createPlaceHolder
  @internal
  ###
  $createPlaceholder = (selector, container = document.body) ->
    $placeholder = $createElementFromSelector(selector)
    $placeholder.addClass('up-placeholder')
    $placeholder.appendTo(container)
    $placeholder

  ###**
  Returns a CSS selector that matches the given element as good as possible.

  This uses, in decreasing order of priority:

  - The element's `up-id` attribute
  - The element's ID
  - The element's name
  - The element's classes
  - The element's tag names

  @function up.util.selectorForElement
  @param {string|Element|jQuery}
    The element for which to create a selector.
  @experimental
  ###
  selectorForElement = (element) ->
    $element = $(element)
    console.debug("Creating selector for element %o, nonUpClasses %o", getElement(element), nonUpClasses($element))
    selector = undefined

    tagName = $element.prop('tagName').toLowerCase()

    if upId = presence($element.attr("up-id"))
      selector = attributeSelector('up-id', upId)
    else if id = presence($element.attr("id"))
      if id.match(/^[a-z0-9\-_]+$/i)
        selector = "##{id}"
      else
        selector = attributeSelector('id', id)
    else if name = presence($element.attr("name"))
      selector = tagName + attributeSelector('name', name)
    else if classes = presence(nonUpClasses($element))
      selector = ''
      for klass in classes
        selector += ".#{klass}"
    else if ariaLabel = presence($element.attr("aria-label"))
      selector = attributeSelector('aria-label', ariaLabel)
    else
      selector = tagName
    selector

  attributeSelector = (attribute, value) ->
    value = value.replace(/"/g, '\\"')
    "[#{attribute}=\"#{value}\"]"

  nonUpClasses = ($element) ->
    classString = $element.attr('class') || ''
    classes = separatedValues(classString)
    reject classes, (klass) -> klass.match(/^up-/)

  # jQuery's implementation of $(...) cannot create elements that have
  # an <html> or <body> tag. So we're using native elements.
  # Also IE9 cannot set innerHTML on a <html> or <head> element.
  createElementFromHtml = (html) ->
    parser = new DOMParser()
    parser.parseFromString(html, 'text/html')

  assignPolyfill = (target, sources...) ->
    for source in sources
      for own key, value of source
        target[key] = value
    target

  ###**
  Merge the own properties of one or more `sources` into the `target` object.

  @function up.util.assign
  @param {Object} target
  @param {Array<Object>} sources...
  @stable
  ###
  assign = Object.assign || assignPolyfill

  valuesPolyfill = (object) ->
    value for key, value of object

  ###**
  Returns an array of values of the given object.

  @function up.util.values
  @param {Object} object
  @return {Array<string>}
  @internal
  ###
  objectValues = Object.values || valuesPolyfill

  ###**
  Returns a new string with whitespace removed from the beginning
  and end of the given string.

  @param {string}
    A string that might have whitespace at the beginning and end.
  @return {string}
    The trimmed string.
  @stable
  ###
  trim = $.trim

  listBlock = (block) ->
    if isString(block)
      (item) -> item[block]
    else
      block

  ###**
  Translate all items in an array to new array of items.

  @function up.util.map
  @param {Array<T>} array
  @param {Function(T, number): any|String} block
    A function that will be called with each element and (optional) iteration index.

    You can also pass a property name as a String,
    which will be collected from each item in the array.
  @return {Array}
    A new array containing the result of each function call.
  @stable
  ###
  map = (array, block) ->
    return [] if array.length == 0
    block = listBlock(block)
    for item, index in array
      block(item, index)

  ###**
  Calls the given function for each element (and, optional, index)
  of the given array.

  @function up.util.each
  @param {Array<T>} array
  @param {Function(T, number)} block
    A function that will be called with each element and (optional) iteration index.
  @stable
  ###
  each = map

  ###**
  Calls the given function for the given number of times.

  @function up.util.times
  @param {number} count
  @param {Function} block
  @stable
  ###
  times = (count, block) ->
    block(iteration) for iteration in [0..(count - 1)]

  ###**
  Returns whether the given argument is `null`.

  @function up.util.isNull
  @param object
  @return {boolean}
  @stable
  ###
  isNull = (object) ->
    object == null

  ###**
  Returns whether the given argument is `undefined`.

  @function up.util.isUndefined
  @param object
  @return {boolean}
  @stable
  ###
  isUndefined = (object) ->
    object == undefined

  ###**
  Returns whether the given argument is not `undefined`.

  @function up.util.isDefined
  @param object
  @return {boolean}
  @stable
  ###
  isDefined = (object) ->
    !isUndefined(object)

  ###**
  Returns whether the given argument is either `undefined` or `null`.

  Note that empty strings or zero are *not* considered to be "missing".

  For the opposite of `up.util.isMissing()` see [`up.util.isGiven()`](/up.util.isGiven).

  @function up.util.isMissing
  @param object
  @return {boolean}
  @stable
  ###
  isMissing = (object) ->
    isUndefined(object) || isNull(object)

  ###**
  Returns whether the given argument is neither `undefined` nor `null`.

  Note that empty strings or zero *are* considered to be "given".

  For the opposite of `up.util.isGiven()` see [`up.util.isMissing()`](/up.util.isMissing).

  @function up.util.isGiven
  @param object
  @return {boolean}
  @stable
  ###
  isGiven = (object) ->
    !isMissing(object)

  # isNan = (object) ->
  #   isNumber(value) && value != +value

  ###**
  Return whether the given argument is considered to be blank.

  This returns `true` for:

  - `undefined`
  - `null`
  - Empty strings
  - Empty arrays
  - An object without own enumerable properties

  All other arguments return `false`.

  @function up.util.isBlank
  @param object
  @return {boolean}
  @stable
  ###
  isBlank = (object) ->
    return true if isMissing(object)
    return false if isFunction(object)
    return true if isObject(object) && Object.keys(object).length == 0 # object
    return true if object.length == 0 # string, array, jQuery
    return false

  ###**
  Returns the given argument if the argument is [present](/up.util.isPresent),
  otherwise returns `undefined`.

  @function up.util.presence
  @param object
  @param {Function(T): boolean} [tester=up.util.isPresent]
    The function that will be used to test whether the argument is present.
  @return {T|undefined}
  @stable
  ###
  presence = (object, tester = isPresent) ->
    if tester(object) then object else undefined

  ###**
  Returns whether the given argument is not [blank](/up.util.isBlank).

  @function up.util.isPresent
  @param object
  @return {boolean}
  @stable
  ###
  isPresent = (object) ->
    !isBlank(object)

  ###**
  Returns whether the given argument is a function.

  @function up.util.isFunction
  @param object
  @return {boolean}
  @stable
  ###
  isFunction = (object) ->
    typeof(object) == 'function'

  ###**
  Returns whether the given argument is a string.

  @function up.util.isString
  @param object
  @return {boolean}
  @stable
  ###
  isString = (object) ->
    typeof(object) == 'string' || object instanceof String

  ###**
  Returns whether the given argument is a number.

  Note that this will check the argument's *type*.
  It will return `false` for a string like `"123"`.

  @function up.util.isNumber
  @param object
  @return {boolean}
  @stable
  ###
  isNumber = (object) ->
    typeof(object) == 'number' || object instanceof Number

  ###**
  Returns whether the given argument is an options hash,

  Differently from [`up.util.isObject()`], this returns false for
  functions, jQuery collections, promises, `FormData` instances and arrays.

  @function up.util.isOptions
  @param object
  @return {boolean}
  @internal
  ###
  isOptions = (object) ->
    typeof(object) == 'object' && !isNull(object) && (isUndefined(object.constructor) || object.constructor == Object)

  ###**
  Returns whether the given argument is an object.

  This also returns `true` for functions, which may behave like objects in JavaScript.

  @function up.util.isObject
  @param object
  @return {boolean}
  @stable
  ###
  isObject = (object) ->
    typeOfResult = typeof(object)
    (typeOfResult == 'object' && !isNull(object)) || typeOfResult == 'function'

  ###**
  Returns whether the given argument is a DOM element.

  @function up.util.isElement
  @param object
  @return {boolean}
  @stable
  ###
  isElement = (object) ->
    !!(object && object.nodeType == 1)

  ###**
  Returns whether the given argument is a jQuery collection.

  @function up.util.isJQuery
  @param object
  @return {boolean}
  @stable
  ###
  isJQuery = (object) ->
    object instanceof jQuery

  ###**
  Returns whether the given argument is an object with a `then` method.

  @function up.util.isPromise
  @param object
  @return {boolean}
  @stable
  ###
  isPromise = (object) ->
    isObject(object) && isFunction(object.then)

  ###**
  Returns whether the given argument is an array.

  @function up.util.isArray
  @param object
  @return {boolean}
  @stable
  ###
  # https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray
  isArray = Array.isArray

  ###**
  Returns whether the given argument is a `FormData` instance.

  Always returns `false` in browsers that don't support `FormData`.

  @function up.util.isFormData
  @param object
  @return {boolean}
  @internal
  ###
  isFormData = (object) ->
    object instanceof FormData

  ###**
  Converts the given array-like argument into an array.

  Returns the array.

  @function up.util.toArray
  @param object
  @return {Array}
  @stable
  ###
  toArray = (object) ->
    Array.prototype.slice.call(object)

  ###**
  Returns a shallow copy of the given array or object.

  @function up.util.copy
  @param {Object|Array} object
  @return {Object|Array}
  @stable
  ###
  copy = (object)  ->
    if isArray(object)
      object = object.slice()
    else if isOptions(object)
      object = assign({}, object)
    else
      up.fail('Cannot copy %o', object)
    object

  ###**
  If given a jQuery collection, returns the first native DOM element in the collection.
  If given a string, returns the first element matching that string.
  If given any other argument, returns the argument unchanged.

  @function up.util.element
  @param {jQuery|Element|String} object
  @return {Element}
  @internal
  ###
  getElement = (object) ->
    if isJQuery(object)
      object.get(0)
    else if isString(object)
      $(object).get(0)
    else
      object

  ###**
  Creates a new object by merging together the properties from the given objects.

  @function up.util.merge
  @param {Array<Object>} sources...
  @return Object
  @stable
  ###
  merge = (sources...) ->
    assign({}, sources...)

  ###**
  Creates a new object by recursively merging together the properties from the given objects.

  @function up.util.deepMerge
  @param {Array<Object>} sources...
  @return Object

  @internal
  ###
  deepMerge = (sources...) ->
    target = {}
    for source in sources
      for key, newValue of source
        if isOptions(newValue)
          oldValue = target[key]
          if isOptions(oldValue)
            newValue = deepMerge(oldValue, newValue)
        target[key] = newValue
    target

  ###**
  Creates an options hash from the given argument and some defaults.

  The semantics of this function are confusing.
  We want to get rid of this in the future.

  @function up.util.options
  @param {Object} object
  @param {Object} [defaults]
  @return {Object}
  @internal
  ###
  newOptions = (object, defaults) ->
    if defaults
      deepMerge(defaults, object)
    else if object
      copy(object)
    else
      {}

  ###**
  Returns the first argument that is considered [given](/up.util.isGiven).

  This function is useful when you have multiple option sources and the value can be boolean.
  In that case you cannot change the sources with a `||` operator
  (since that doesn't short-circuit at `false`).
  
  @function up.util.option
  @param {Array} args...
  @internal
  ###
  option = (args...) ->
    detect(args, isGiven)

  ###**
  Passes each element in the given array to the given function.
  Returns the first element for which the function returns a truthy value.

  If no object matches, returns `undefined`.

  @function up.util.detect
  @param {Array<T>} array
  @param {Function(T): boolean} tester
  @return {T|undefined}
  @stable
  ###
  detect = (array, tester) ->
    match = undefined
    for element in array
      if tester(element)
        match = element
        break
    match

  ###**
  Returns whether the given function returns a truthy value
  for any element in the given array.

  @function up.util.any
  @param {Array<T>} array
  @param {Function(T, number): boolean} tester
    A function that will be called with each element and (optional) iteration index.

  @return {boolean}
  @experimental
  ###
  any = (array, tester) ->
    tester = listBlock(tester)
    match = false
    for element, index in array
      if tester(element, index)
        match = true
        break
    match

  ###**
  Returns whether the given function returns a truthy value
  for all elements in the given array.

  @function up.util.all
  @param {Array<T>} array
  @param {Function(T, number): boolean} tester
    A function that will be called with each element and (optional) iteration index.

  @return {boolean}
  @experimental
  ###
  all = (array, tester) ->
    tester = listBlock(tester)
    match = true
    for element, index in array
      unless tester(element, index)
        match = false
        break
    match

  ###**
  Returns all elements from the given array that are
  neither `null` or `undefined`.

  @function up.util.compact
  @param {Array<T>} array
  @return {Array<T>}
  @stable
  ###
  compact = (array) ->
    select array, isGiven

  ###**
  Returns the given array without duplicates.

  @function up.util.uniq
  @param {Array<T>} array
  @return {Array<T>}
  @stable
  ###
  uniq = (array) ->
    return array if array.length < 2
    setToArray(arrayToSet(array))

  ###**
  This function is like [`uniq`](/up.util.uniq), accept that
  the given function is invoked for each element to generate the value
  for which uniquness is computed.

  @function up.util.uniqBy
  @param {Array<T>} array
  @param {Function<T>: any} array
  @return {Array<T>}
  @experimental
  ###
  uniqBy = (array, mapper) ->
    return array if array.length < 2
    mapper = listBlock(mapper)
    set = new Set()
    select array, (elem, index) ->
      mapped = mapper(elem, index)
      if set.has(mapped)
        false
      else
        set.add(mapped)
        true

  ###**
  @function up.util.setToArray
  @internal
  ###
  setToArray = (set) ->
    array = []
    set.forEach (elem) -> array.push(elem)
    array

  ###*
  @function up.util.arrayToSet
  @internal
  ###
  arrayToSet = (array) ->
    set = new Set()
    array.forEach (elem) -> set.add(elem)
    set

  ###**
  Returns all elements from the given array that return
  a truthy value when passed to the given function.

  @function up.util.select
  @param {Array<T>} array
  @param {Function(T, number): boolean} tester
  @return {Array<T>}
  @stable
  ###
  select = (array, tester) ->
    tester = listBlock(tester)
    matches = []
    each array, (element, index) ->
      if tester(element, index)
        matches.push(element)
    matches

  ###**
  Returns all elements from the given array that do not return
  a truthy value when passed to the given function.

  @function up.util.reject
  @param {Array<T>} array
  @param {Function(T, number): boolean} tester
  @return {Array<T>}
  @stable
  ###
  reject = (array, tester) ->
    tester = listBlock(tester)
    select(array, (element, index) -> !tester(element, index))

  ###**
  Returns the intersection of the given two arrays.

  Implementation is not optimized. Don't use it for large arrays.

  @function up.util.intersect
  @internal
  ###
  intersect = (array1, array2) ->
    select array1, (element) ->
      contains(array2, element)

  addClass = (element, klassOrKlasses) ->
    changeClassList(element, klassOrKlasses, 'add')

  removeClass = (element, klassOrKlasses) ->
    changeClassList(element, klassOrKlasses, 'remove')

  changeClassList = (element, klassOrKlasses, fnName) ->
    classList = getElement(element).classList
    if isArray(klassOrKlasses)
      each klassOrKlasses, (klass) ->
        classList[fnName](klass)
    else
      classList[fnName](klassOrKlasses)

  addTemporaryClass = (element, klassOrKlasses) ->
    addClass(element, klassOrKlasses)
    -> removeClass(element, klassOrKlasses)

  hasClass = (element, klass) ->
    classList = getElement(element).classList
    classList.contains(klass)

  ###**
  Returns the first [present](/up.util.isPresent) element attribute
  among the given list of attribute names.

  @function up.util.presentAttr
  @internal
  ###
  presentAttr = ($element, attrNames...) ->
    values = ($element.attr(attrName) for attrName in attrNames)
    detect(values, isPresent)

  ###**
  Waits for the given number of milliseconds, the runs the given callback.

  Instead of `up.util.setTimer(0, fn)` you can also use [`up.util.nextFrame(fn)`](/up.util.nextFrame).

  @function up.util.setTimer
  @param {number} millis
  @param {Function} callback
  @stable
  ###
  setTimer = (millis, callback) ->
    setTimeout(callback, millis)

  ###**
  Schedules the given function to be called in the
  next JavaScript execution frame.

  @function up.util.nextFrame
  @param {Function} block
  @stable
  ###
  nextFrame = (block) ->
    setTimeout(block, 0)

  ###**
  Queue a function to be executed in the next microtask.

  @function up.util.queueMicrotask
  @param {Function} task
  @internal
  ###
  microtask = (task) ->
    Promise.resolve().then(task)

  ###**
  Returns the last element of the given array.

  @function up.util.last
  @param {Array<T>} array
  @return {T}
  ###
  last = (array) ->
    array[array.length - 1]

  ###**
  Measures the drawable area of the document.

  @function up.util.clientSize
  @internal
  ###
  clientSize = ->
    element = document.documentElement
    width: element.clientWidth
    height: element.clientHeight

  ###**
  Returns the width of a scrollbar.

  This only runs once per page load.

  @function up.util.scrollbarWidth
  @internal
  ###
  scrollbarWidth = memoize ->
    # This is how Bootstrap does it also:
    # https://github.com/twbs/bootstrap/blob/c591227602996c542b9fd0cb65cff3cc9519bdd5/dist/js/bootstrap.js#L1187
    $outer = $('<div>')
    outer = $outer.get(0)
    $outer.attr('up-viewport', '')
    writeInlineStyle outer,
      position:  'absolute'
      top:       '0'
      left:      '0'
      width:     '100px'
      height:    '100px' # Firefox needs at least 100px to show a scrollbar
      overflowY: 'scroll'
    $outer.appendTo(document.body)
    width = outer.offsetWidth - outer.clientWidth
    $outer.remove()
    width

  ###**
  Returns whether the given element is currently showing a vertical scrollbar.

  @function up.util.documentHasVerticalScrollbar
  @internal
  ###
  documentHasVerticalScrollbar = ->
    body = document.body
    $body = $(body)
    html = document.documentElement

    bodyOverflow = readComputedStyle($body, 'overflowY')

    forcedScroll = (bodyOverflow == 'scroll')
    forcedHidden = (bodyOverflow == 'hidden')

    forcedScroll || (!forcedHidden && html.scrollHeight > html.clientHeight)

  ###**
  Temporarily sets the CSS for the given element.

  @function up.util.writeTemporaryStyle
  @param {jQuery} $element
  @param {Object} css
  @param {Function} [block]
    If given, the CSS is set, the block is called and
    the old CSS is restored.
  @return {Function}
    A function that restores the original CSS when called.
  @internal
  ###
  writeTemporaryStyle = (elementOrSelector, newCss, block) ->
    $element = $(elementOrSelector)
    oldStyles = readInlineStyle($element, Object.keys(newCss))
    restoreOldStyles = -> writeInlineStyle($element, oldStyles)
    writeInlineStyle($element, newCss)
    if block
      # If a block was passed, we run the block and restore old styles.
      block()
      restoreOldStyles()
    else
      # If no block was passed, we return the restoration function.
      restoreOldStyles

  ###**
  Forces a repaint of the given element.

  @function up.util.forceRepaint
  @internal
  ###
  forceRepaint = (element) ->
    element = getElement(element)
    element.offsetHeight

  ###*
  @function up.util.finishTransition
  @internal
  ###
  concludeCssTransition = (element) ->
    undo = writeTemporaryStyle(element, transition: 'none')
    # Browsers need to paint at least one frame without a transition to stop the
    # animation. In theory we could just wait until the next paint, but in case
    # someone will set another transition after us, let's force a repaint here.
    forceRepaint(element)
    return undo

  ###**
  @internal
  ###
  margins = (selectorOrElement) ->
    element = getElement(selectorOrElement)
    top:    readComputedStyleNumber(element, 'marginTop')
    right:  readComputedStyleNumber(element, 'marginRight')
    bottom: readComputedStyleNumber(element, 'marginBottom')
    left:   readComputedStyleNumber(element, 'marginLeft')

  ###**
  Measures the given element.

  @function up.util.measure
  @internal
  ###
  measure = ($element, opts) ->
    opts = newOptions(opts, relative: false, inner: false, includeMargin: false)

    if opts.relative
      if opts.relative == true
        coordinates = $element.position()
      else
        # A relative context element is given
        $context = $(opts.relative)
        elementCoords = $element.offset()
        if $context.is(document)
          # The document is always at the origin
          coordinates = elementCoords
        else
          contextCoords = $context.offset()
          coordinates =
            left: elementCoords.left - contextCoords.left
            top: elementCoords.top - contextCoords.top
    else
      coordinates = $element.offset()
    
    box = 
      left: coordinates.left
      top: coordinates.top

    if opts.inner
      box.width = $element.width()
      box.height = $element.height()
    else
      box.width = $element.outerWidth()
      box.height = $element.outerHeight()

    if opts.includeMargin
      mgs = margins($element)
      box.left -= mgs.left
      box.top -= mgs.top
      box.height += mgs.top + mgs.bottom
      box.width += mgs.left + mgs.right

    box

  ###**
  Copies all attributes from the source element to the target element.

  @function up.util.copyAttributes
  @internal
  ###
  copyAttributes = ($source, $target) ->
    for attr in $source.get(0).attributes
      if attr.specified
        $target.attr(attr.name, attr.value)

  ###**
  Looks for the given selector in the element and its descendants.

  @function up.util.selectInSubtree
  @internal
  ###
  selectInSubtree = ($element, selector) ->
    # This implementation is faster than $element.find(selector).addBack(Seelctor)
    $matches = $()
    if $element.is(selector)
      $matches = $matches.add($element)
    $matches = $matches.add($element.find(selector))
    $matches

  ###**
  Looks for the given selector in the element, its descendants and its ancestors.

  @function up.util.selectInDynasty
  @internal
  ###
  selectInDynasty = ($element, selector) ->
    $subtree = selectInSubtree($element, selector)
    $ancestors = $element.parents(selector)
    $subtree.add($ancestors)

  ###**
  Returns whether the given keyboard event involved the ESC key.

  @function up.util.escapePressed
  @internal
  ###
  escapePressed = (event) ->
    event.keyCode == 27

  ###**
  Returns whether the given array or string contains the given element or substring.

  @function up.util.contains
  @param {Array|string} arrayOrString
  @param elementOrSubstring
  @stable
  ###
  contains = (arrayOrString, elementOrSubstring) ->
    arrayOrString.indexOf(elementOrSubstring) >= 0

  ###**
  @function up.util.castedAttr
  @internal
  ###
  castedAttr = ($element, attrName) ->
    value = $element.attr(attrName)
    switch value
      when 'false' then false
      when 'true', '', attrName then true
      else value # other strings, undefined, null, ...

#  castsToTrue = (object) ->
#    String(object) == "true"
#
#  castsToFalse = (object) ->
#    String(object) == "false"

  ###**
  Returns a copy of the given object that only contains
  the given properties.

  @function up.util.only
  @param {Object} object
  @param {Array} keys...
  @stable
  ###
  only = (object, properties...) ->
    filtered = {}
    for property in properties
      if property of object
        filtered[property] = object[property]
    filtered

  ###**
  Returns a copy of the given object that contains all except
  the given properties.

  @function up.util.except
  @param {Object} object
  @param {Array} keys...
  @stable
  ###
  except = (object, properties...) ->
    filtered = copy(object)
    for property in properties
      delete filtered[property]
    filtered

  ###**
  @function up.util.isUnmodifiedKeyEvent
  @internal
  ###
  isUnmodifiedKeyEvent = (event) ->
    not (event.metaKey or event.shiftKey or event.ctrlKey)

  ###**
  @function up.util.isUnmodifiedMouseEvent
  @internal
  ###
  isUnmodifiedMouseEvent = (event) ->
    isLeftButton = isUndefined(event.button) || event.button == 0
    isLeftButton && isUnmodifiedKeyEvent(event)

  ###**
  Returns a promise that will never be resolved.

  @function up.util.unresolvablePromise
  @experimental
  ###
  unresolvablePromise = ->
    new Promise(noop)

  ###**
  Returns an empty jQuery collection.

  @function up.util.nullJQuery
  @internal
  ###
  nullJQuery = ->
    $()

  ###**
  On the given element, set attributes that are still missing.

  @function up.util.setMissingAttrs
  @internal
  ###
  setMissingAttrs = ($element, attrs) ->
    for key, value of attrs
      if isMissing($element.attr(key))
        $element.attr(key, value)

  ###**
  Removes the given element from the given array.

  This changes the given array.

  @function up.util.remove
  @param {Array<T>} array
  @param {T} element
  @stable
  ###
  remove = (array, element) ->
    index = array.indexOf(element)
    if index >= 0
      array.splice(index, 1)
      element

  ###**
  If the given `value` is a function, calls the function with the given `args`.
  Otherwise it just returns `value`.

  @function up.util.evalOption
  @internal
  ###
  evalOption = (value, args...) ->
    if isFunction(value)
      value(args...)
    else
      value

  ###**
  @function up.util.config
  @param {Object|Function} blueprint
    Default configuration options.
    Will be restored by calling `reset` on the returned object.
  @return {Object}
    An object with a `reset` function.
  @internal
  ###
  config = (blueprint) ->
    hash = openConfig(blueprint)
    Object.preventExtensions(hash)
    hash

  ###**
  @function up.util.openConfig
  @internal
  ###
  openConfig = (blueprint = {}) ->
    hash = {}
    hash.reset = ->
      opts = blueprint
      opts = opts() if isFunction(opts)
      assign(hash, opts)
    hash.reset()
    hash

  ###**
  @function up.util.unwrapElement
  @internal
  ###
  unwrapElement = (wrapper) ->
    wrapper = getElement(wrapper)
    parent = wrapper.parentNode;
    wrappedNodes = toArray(wrapper.childNodes)
    each wrappedNodes, (wrappedNode) ->
      parent.insertBefore(wrappedNode, wrapper)
    parent.removeChild(wrapper)

  ###**
  @function up.util.offsetParent
  @internal
  ###
  offsetParent = ($element) ->
    $match = undefined
    while ($element = $element.parent()) && $element.length
      position = readComputedStyle($element, 'position')
      if position == 'absolute' || position == 'relative' || $element.is('body')
        $match = $element
        break
    $match

  ###**
  Returns if the given element has a `fixed` position.

  @function up.util.isFixed
  @internal
  ###
  isFixed = (element) ->
    $element = $(element)
    loop
      position = readComputedStyle($element, 'position')
      if position == 'fixed'
        return true
      else
        $element = $element.parent()
        if $element.length == 0 || $element.is(document)
          return false

  ###**
  @function up.util.fixedToAbsolute
  @internal
  ###
  fixedToAbsolute = (element, $viewport) ->
    $element = $(element)
    $futureOffsetParent = offsetParent($element)
    # To get a fixed elements distance from the edge of the screen,
    # use position(), not offset(). offset() would include the current
    # scrollTop of the viewport.
    elementCoords = $element.position()
    futureParentCoords = $futureOffsetParent.offset()
    writeInlineStyle $element,
      position: 'absolute'
      left: elementCoords.left - futureParentCoords.left
      top: elementCoords.top - futureParentCoords.top + $viewport.scrollTop()
      right: ''
      bottom: ''

#  argNames = (fun) ->
#    code = fun.toString()
#    pattern = new RegExp('\\(([^\\)]*)\\)')
#    if match = code.match(pattern)
#      match[1].split(/\s*,\s*/)
#    else
#      error('Could not parse argument names of %o', fun)

  ###**
  Throws a [JavaScript error](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error)
  with the given message.

  The message will also be printed to the [error log](/up.log.error). Also a notification will be shown at the bottom of the screen.

  The message may contain [substitution marks](https://developer.mozilla.org/en-US/docs/Web/API/console#Using_string_substitutions).

  \#\#\# Examples

      up.fail('Division by zero')
      up.fail('Unexpected result %o', result)

  @function up.fail
  @param {string} message
    A message with details about the error.

    The message can contain [substitution marks](https://developer.mozilla.org/en-US/docs/Web/API/console#Using_string_substitutions)
    like `%s` or `%o`.
  @param {Array<string>} vars...
    A list of variables to replace any substitution marks in the error message.
  @experimental
  ###
  fail = (args...) ->
    if isArray(args[0])
      messageArgs = args[0]
      toastOptions = args[1] || {}
    else
      messageArgs = args
      toastOptions = {}

    up.log.error(messageArgs...)

    whenReady().then -> up.toast.open(messageArgs, toastOptions)

    asString = up.browser.sprintf(messageArgs...)
    throw new Error(asString)

  ESCAPE_HTML_ENTITY_MAP =
    "&": "&amp;"
    "<": "&lt;"
    ">": "&gt;"
    '"': '&quot;'

  ###**
  Escapes the given string of HTML by replacing control chars with their HTML entities.

  @function up.util.escapeHtml
  @param {string} string
    The text that should be escaped
  @experimental
  ###
  escapeHtml = (string) ->
    string.replace /[&<>"]/g, (char) -> ESCAPE_HTML_ENTITY_MAP[char]

  pluckKey = (object, key) ->
    value = object[key]
    delete object[key]
    value

  renameKey = (object, oldKey, newKey) ->
    object[newKey] = pluckKey(object, oldKey)

  deprecateRenamedKey = (object, oldKey, newKey) ->
    if isDefined(object[oldKey])
      up.log.warn('Deprecated: Object key { %s } has been renamed to { %s } (found in %o)', oldKey, newKey, object)
      renameKey(object, oldKey, newKey)

  pluckData = (elementOrSelector, key) ->
    $element = $(elementOrSelector)
    value = $element.data(key)
    $element.removeData(key)
    value

  extractOptions = (args) ->
    lastArg = last(args)
    if isOptions(lastArg)
      args.pop()
    else
      {}

  CASE_CONVERSION_GROUP = /[^\-\_]+?(?=[A-Z\-\_]|$)/g

  convertCase = (string, separator, fn) ->
    parts = string.match(CASE_CONVERSION_GROUP)
    parts = map parts, fn
    parts.join(separator)

  ###**
  Returns a copy of the given string that is transformed to `kebab-case`.

  @function up.util.kebabCase
  @param {string} string
  @return {string}
  @internal
  ###
  kebabCase = (string) ->
    convertCase string, '-', (part) -> part.toLowerCase()

  ###**
  Returns a copy of the given string that is transformed to `camelCase`.

  @function up.util.camelCase
  @param {string} string
  @return {string}
  @internal
  ###
  camelCase = (string) ->
    convertCase string, '', (part, i) ->
      if i == 0
        part.toLowerCase()
      else
        part.charAt(0).toUpperCase() + part.substr(1).toLowerCase()

  ###**
  Returns a copy of the given object with all keys renamed
  in `kebab-case`.

  Does not change the given object.

  @function up.util.kebabCaseKeys
  @param {object} obj
  @return {object}
  @internal
  ###
  kebabCaseKeys = (obj) ->
    copyWithRenamedKeys(obj, kebabCase)

  ###**
  Returns a copy of the given object with all keys renamed
  in `camelCase`.

  Does not change the given object.

  @function up.util.camelCaseKeys
  @param {object} obj
  @return {object}
  @internal
  ###
  camelCaseKeys = (obj) ->
    copyWithRenamedKeys(obj, camelCase)

  copyWithRenamedKeys = (obj, keyTransformer) ->
    result = {}
    for k, v of obj
      k = keyTransformer(k)
      result[k] = v
    result

  opacity = (element) ->
    readComputedStyleNumber(element, 'opacity')

  whenReady = memoize ->
    if $.isReady
      Promise.resolve()
    else
      new Promise (resolve) -> $(resolve)

  identity = (arg) -> arg

  ###**
  Returns whether the given element has been detached from the DOM
  (or whether it was never attached).

  @function up.util.isDetached
  @internal
  ###
  isDetached = (element) ->
    element = getElement(element)
    # This is by far the fastest way to do this
    not $.contains(document.documentElement, element)

  ###**
  Given a function that will return a promise, returns a proxy function
  with an additional `.promise` attribute.

  When the proxy is called, the inner function is called.
  The proxy's `.promise` attribute is available even before the function is called
  and will resolve when the inner function's returned promise resolves.

  If the inner function does not return a promise, the proxy's `.promise` attribute
  will resolve as soon as the inner function returns.

  @function up.util.previewable
  @internal
  ###
  previewable = (fun) ->
    deferred = newDeferred()
    preview = (args...) ->
      funValue = fun(args...)
      # If funValue is again a Promise, it will defer resolution of `deferred`
      # until `funValue` is resolved.
      deferred.resolve(funValue)
      funValue
    preview.promise = deferred.promise()
    preview

  ###**
  A linear task queue whose (2..n)th tasks can be changed at any time.

  @function up.util.DivertibleChain
  @internal
  ###
  class DivertibleChain

    constructor: ->
      @reset()

    reset: =>
      @queue = []
      @currentTask = undefined

    promise: =>
      lastTask = last(@allTasks())
      lastTask?.promise || Promise.resolve()

    allTasks: =>
      tasks = []
      tasks.push(@currentTask) if @currentTask
      tasks = tasks.concat(@queue)
      tasks

    poke: =>
      unless @currentTask # don't start a new task while we're still running one
        if @currentTask = @queue.shift()
          promise = @currentTask()
          always promise, =>
            @currentTask = undefined
            @poke()

    asap: (newTasks...) =>
      @queue = map(newTasks, previewable)
      @poke()
      @promise()

  ###**
  @function up.util.submittedValue
  @internal
  ###
  submittedValue = (fieldOrSelector) ->
    $field = $(fieldOrSelector)
    if $field.is('[type=checkbox], [type=radio]') && !$field.is(':checked')
      undefined
    else
      $field.val()

  ###**
  @function up.util.sequence
  @param {Array<Function>} functions...
  @return {Function}
    A function that will call all `functions` if called.

  @internal
  ###
  sequence = (functions...) ->
    ->
      map functions, (f) -> f()

#  ###**
#  @function up.util.race
#  @internal
#  ###
#  race = (promises...) ->
#    raceDone = newDeferred()
#    each promises, (promise) ->
#      promise.then -> raceDone.resolve()
#    raceDone.promise()

  ###**
  @function up.util.promiseTimer
  @internal
  ###
  promiseTimer = (ms) ->
    timeout = undefined
    promise = new Promise (resolve, reject) ->
      timeout = setTimer(ms, resolve)
    promise.cancel = -> clearTimeout(timeout)
    promise

  ###**
  Returns `'left'` if the center of the given element is in the left 50% of the screen.
  Otherwise returns `'right'`.

  @function up.util.horizontalScreenHalf
  @internal
  ###
  horizontalScreenHalf = ($element) ->
    elementDims = measure($element)
    screenDims = clientSize()
    elementMid = elementDims.left + 0.5 * elementDims.width
    screenMid = 0.5 * screenDims.width
    if elementMid < screenMid
      'left'
    else
      'right'

  ###**
  Like `$old.replaceWith($new)`, but keeps event handlers bound to `$old`.

  Note that this is a memory leak unless you re-attach `$old` to the DOM aferwards.

  @function up.util.detachWith
  @internal
  ###
  detachWith = ($old, $new) ->
    $insertion = $('<div></div>')
    $insertion.insertAfter($old)
    $old.detach()
    $insertion.replaceWith($new)
    $old

  ###**
  Hides the given element faster than `jQuery.fn.hide()`.

  @function up.util.hide
  @param {jQuery|Element} element
  ###
  hide = (element) ->
    writeInlineStyle(element, display: 'none')

  ###**
  Gets the computed style(s) for the given element.

  @function up.util.readComputedStyle
  @param {jQuery|Element} element
  @param {String|Array} propOrProps
    One or more CSS property names in camelCase.
  @return {string|object}
  @internal
  ###
  readComputedStyle = (element, props) ->
    element = getElement(element)
    style = window.getComputedStyle(element)
    extractFromStyleObject(style, props)

  ###**
  Gets a computed style value for the given element.
  If a value is set, the value is parsed to a number before returning.

  @function up.util.readComputedStyleNumber
  @param {jQuery|Element} element
  @param {String} prop
    A CSS property name in camelCase.
  @return {string|object}
  @internal
  ###
  readComputedStyleNumber = (element, prop) ->
    rawValue = readComputedStyle(element, prop)
    if isGiven(rawValue)
      parseFloat(rawValue)
    else
      undefined

  ###**
  Gets the given inline style(s) from the given element's `[style]` attribute.

  @function up.util.readInlineStyle
  @param {jQuery|Element} element
  @param {String|Array} propOrProps
    One or more CSS property names in camelCase.
  @return {string|object}
  @internal
  ###
  readInlineStyle = (element, props) ->
    element = getElement(element)
    style = element.style
    extractFromStyleObject(style, props)

  extractFromStyleObject = (style, keyOrKeys) ->
    if isString(keyOrKeys)
      style[keyOrKeys]
    else # array
      only(style, keyOrKeys...)

  ###**
  Merges the given inline style(s) into the given element's `[style]` attribute.

  @function up.util.readInlineStyle
  @param {jQuery|Element} element
  @param {Object} props
    One or more CSS properties with camelCase keys.
  @return {string|object}
  @internal
  ###
  writeInlineStyle = (element, props) ->
    element = getElement(element)
    style = element.style
    for key, value of props
      value = normalizeStyleValueForWrite(key, value)
      style[key] = value

  normalizeStyleValueForWrite = (key, value) ->
    if isMissing(value)
      value = ''
    else if CSS_LENGTH_PROPS.has(key)
      value = cssLength(value)
    value

  CSS_LENGTH_PROPS = arrayToSet [
    'top', 'right', 'bottom', 'left',
    'padding', 'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft',
    'margin', 'marginTop', 'marginRight', 'marginBottom', 'marginLeft',
    'width', 'height',
    'maxWidth', 'maxHeight',
    'minWidth', 'minHeight',
  ]

  ###*
  Converts the given value to a CSS length value, adding a `px` unit if required.

  @function up.util.cssLength
  @internal
  ###
  cssLength = (obj) ->
    if isNumber(obj) || (isString(obj) && /^\d+$/.test(obj))
      obj.toString() + "px"
    else
      obj

  ###*
  Returns whether the given element has a CSS transition set.

  @function up.util.hasCssTransition
  @return {boolean}
  @internal
  ###
  hasCssTransition = (elementOrStyleHash) ->
    if isOptions(elementOrStyleHash)
      style = elementOrStyleHash
    else
      element = getElement(element)
      style = getComputedStyle(element)

    prop = style.transitionProperty
    duration = style.transitionDuration
    # The default transition for elements is actually "all 0s ease 0s"
    # instead of "none", although that has the same effect as "none".
    noTransition = (prop == 'none' || (prop == 'all' && duration == 0))
    not noTransition

  ###**
  Flattens the given `array` a single level deep.

  @function up.util.flatten
  @param {Array} array
    An array which might contain other arrays
  @return {Array}
    The flattened array
  @internal
  ###
  flatten = (array) ->
    flattened = []
    for object in array
      if isArray(object)
        flattened = flattened.concat(object)
      else
        flattened.push(object)
    flattened

  flatMap = (array, block) ->
    flatten map(array, block)

  ###**
  Returns whether the given value is truthy.

  @function up.util.isTruthy
  @internal
  ###
  isTruthy = (object) ->
    !!object

  ###**
  Sets the given callback as both fulfillment and rejection handler for the given promise.

  @function up.util.always
  @internal
  ###
  always = (promise, callback) ->
    promise.then(callback, callback)

  ###**
  # Registers an empty rejection handler with the given promise.
  # This prevents browsers from printing "Uncaught (in promise)" to the error
  # console when the promise is rejection.
  #
  # This is helpful for event handlers where it is clear that no rejection
  # handler will be registered:
  #
  #     up.on('submit', 'form[up-target]', (event, $form) => {
  #       promise = up.submit($form)
  #       up.util.muteRejection(promise)
  #     })
  #
  # Does nothing if passed a missing value.
  #
  # @function up.util.muteRejection
  # @param {Promise|undefined|null} promise
  # @return {Promise}
  ###
  muteRejection = (promise) ->
    promise?.catch(noop)

  ###**
  @function up.util.newDeferred
  @internal
  ###
  ###**
  @function up.util.newDeferred
  @internal
  ###
  newDeferred = ->
    resolveFn = undefined
    rejectFn = undefined
    nativePromise = new Promise (givenResolve, givenReject) ->
      resolveFn = givenResolve
      rejectFn = givenReject
    nativePromise.resolve = resolveFn
    nativePromise.reject = rejectFn
    nativePromise.promise = -> nativePromise # just return self
    nativePromise

  ###**
  Calls the given block. If the block throws an exception,
  a rejected promise is returned instead.

  @function up.util.rejectOnError
  @internal
  ###
  rejectOnError = (block) ->
    try
      block()
    catch error
      Promise.reject(error)

  ###**
  Returns whether the given element is a descendant of the `<body>` element.

  @function up.util.isBodyDescendant
  @internal
  ###
  isBodyDescendant = (element) ->
    $(element).parents('body').length > 0

  isEqual = (a, b) ->
    if typeof(a) != typeof(b)
      false
    else if isArray(a)
      a.length == b.length && all(a, (elem, index) -> isEqual(elem, b[index]))
    else if isObject(a)
      fail('isEqual cannot compare objects yet')
    else
      a == b

  separatedValues = (string, separator = ' ') ->
    values = string.split(separator)
    values = map(values, trim)
    values = select(values, isPresent)
    values

  wrapArray = (objOrArray) ->
    if isUndefined(objOrArray)
      []
    else if isArray(objOrArray)
      objOrArray
    else
      [objOrArray]

  isEqual = (a, b) ->
    if typeof(a) != typeof(b)
      false
    else if isArray(a)
      a.length == b.length && all(a, (elem, index) -> isEqual(elem, b[index]))
    else if isObject(a)
      fail('isEqual cannot compare objects yet')
    else
      a == b

  offsetParent: offsetParent
  fixedToAbsolute: fixedToAbsolute
  isFixed: isFixed
  presentAttr: presentAttr
  parseUrl: parseUrl
  normalizeUrl: normalizeUrl
  normalizeMethod: normalizeMethod
  methodAllowsPayload: methodAllowsPayload
  createElementFromHtml: createElementFromHtml
  $createElementFromSelector: $createElementFromSelector
  $createPlaceholder: $createPlaceholder
  selectorForElement: selectorForElement
  attributeSelector: attributeSelector
  assign: assign
  assignPolyfill: assignPolyfill
  copy: copy
  merge: merge
  deepMerge: deepMerge
  options: newOptions
  option: option
  fail: fail
  each: each
  map: map
  flatMap: flatMap
  times: times
  any: any
  all: all
  detect: detect
  select: select
  reject: reject
  intersect: intersect
  compact: compact
  uniq: uniq
  uniqBy: uniqBy
  last: last
  isNull: isNull
  isDefined: isDefined
  isUndefined: isUndefined
  isGiven: isGiven
  isMissing: isMissing
  isPresent: isPresent
  isBlank: isBlank
  presence: presence
  isObject: isObject
  isFunction: isFunction
  isString: isString
  isNumber: isNumber
  isElement: isElement
  isJQuery: isJQuery
  isPromise: isPromise
  isOptions: isOptions
  isArray: isArray
  isFormData: isFormData
  isUnmodifiedKeyEvent: isUnmodifiedKeyEvent
  isUnmodifiedMouseEvent: isUnmodifiedMouseEvent
  nullJQuery: nullJQuery
  element: getElement
  setTimer: setTimer
  nextFrame: nextFrame
  measure: measure
  addClass: addClass
  removeClass: removeClass
  hasClass: hasClass
  addTemporaryClass: addTemporaryClass
  writeTemporaryStyle: writeTemporaryStyle
  forceRepaint: forceRepaint
  concludeCssTransition: concludeCssTransition
  escapePressed: escapePressed
  copyAttributes: copyAttributes
  selectInSubtree: selectInSubtree
  selectInDynasty: selectInDynasty
  contains: contains
  toArray: toArray
  castedAttr: castedAttr
  clientSize: clientSize
  only: only
  except: except
  trim: trim
  unresolvablePromise: unresolvablePromise
  setMissingAttrs: setMissingAttrs
  remove: remove
  memoize: memoize
  scrollbarWidth: scrollbarWidth
  documentHasVerticalScrollbar: documentHasVerticalScrollbar
  config: config
  openConfig: openConfig
  unwrapElement: unwrapElement
  camelCase: camelCase
  camelCaseKeys: camelCaseKeys
  kebabCase: kebabCase
  kebabCaseKeys: kebabCaseKeys
  error: fail
  pluckData: pluckData
  pluckKey: pluckKey
  renameKey: renameKey
  deprecateRenamedKey: deprecateRenamedKey
  extractOptions: extractOptions
  isDetached: isDetached
  noop: noop
  asyncNoop: asyncNoop
  opacity: opacity
  whenReady: whenReady
  identity: identity
  escapeHtml: escapeHtml
  DivertibleChain: DivertibleChain
  submittedValue: submittedValue
  sequence: sequence
  promiseTimer: promiseTimer
  previewable: previewable
  evalOption: evalOption
  horizontalScreenHalf: horizontalScreenHalf
  detachWith: detachWith
  flatten: flatten
  isTruthy: isTruthy
  newDeferred: newDeferred
  always: always
  muteRejection: muteRejection
  rejectOnError: rejectOnError
  isBodyDescendant: isBodyDescendant
  isCrossDomain: isCrossDomain
  microtask: microtask
  isEqual: isEqual
  hide: hide
  cssLength: cssLength
  readComputedStyle: readComputedStyle
  readComputedStyleNumber: readComputedStyleNumber
  readInlineStyle: readInlineStyle
  writeInlineStyle: writeInlineStyle
  hasCssTransition: hasCssTransition
  separatedValues : separatedValues
  wrapArray: wrapArray
  values: objectValues

)(jQuery)

up.fail = up.util.fail
