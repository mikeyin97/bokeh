Model = require "../../model"
p = require "../../core/properties"

class LogMapper extends Model
  initialize: (attrs, options) ->
    super(attrs, options)

    @define_computed_property('mapper_state', @_mapper_state, true)
    @add_dependencies('mapper_state', this, ['source_range', 'target_range'])
    @add_dependencies('mapper_state', @get('source_range'), ['start', 'end'])
    @add_dependencies('mapper_state', @get('target_range'), ['start', 'end'])

  map_to_target: (x) ->
    [scale, offset, inter_scale, inter_offset] = @get('mapper_state')

    result = 0

    if inter_scale == 0
      intermediate = 0

    else
      intermediate = (Math.log(x) - inter_offset) / inter_scale
      if isNaN(intermediate) or not isFinite(intermediate)
        intermediate = 0

    result = intermediate * scale + offset

    return result

  v_map_to_target: (xs) ->
    [scale, offset, inter_scale, inter_offset] = @get('mapper_state')

    result = new Float64Array(xs.length)

    if inter_scale == 0
      intermediate = xs.map (i) -> 0

    else
      intermediate = xs.map (i) -> (Math.log(i) - inter_offset) / inter_scale

      for x, idx in intermediate
        if isNaN(intermediate[idx]) or not isFinite(intermediate[idx])
          intermediate[idx] = 0

    for x, idx in xs
      result[idx] = intermediate[idx] * scale + offset

    return result

  map_from_target: (xprime) ->
    [scale, offset, inter_scale, inter_offset] = @get('mapper_state')
    intermediate = (xprime - offset) / scale
    intermediate = Math.exp(inter_scale * intermediate + inter_offset)

    return intermediate

  v_map_from_target: (xprimes) ->
    result = new Float64Array(xprimes.length)
    [scale, offset, inter_scale, inter_offset] = @get('mapper_state')
    intermediate = xprimes.map (i) -> (i - offset) / scale
    for x, idx in xprimes
      result[idx] = Math.exp(inter_scale * intermediate[idx] + inter_offset)
    return result

  _get_safe_scale: (orig_start, orig_end) ->
    if orig_start < 0
      start = 0
    else
      start = orig_start

    if orig_end < 0
      end = 0
    else
      end = orig_end

    if start == end
      if start == 0
        [start, end] = [1, 10]
      else
        log_val = Math.log(start) / Math.log(10)
        start = Math.pow(10, Math.floor(log_val))

        if Math.ceil(log_val) != Math.floor(log_val)
          end = Math.pow(10, Math.ceil(log_val))
        else
          end = Math.pow(10, Math.ceil(log_val) + 1)

    return [start, end]

  _mapper_state: () ->
    source_start = @get('source_range').get('start')
    source_end   = @get('source_range').get('end')
    target_start = @get('target_range').get('start')
    target_end   = @get('target_range').get('end')

    screen_range = target_end - target_start
    [start, end] = @_get_safe_scale(source_start, source_end)

    if start == 0
      inter_scale = Math.log(end)
      inter_offset = 0
    else
      inter_scale = Math.log(end) - Math.log(start)
      inter_offset = Math.log(start)

    scale = screen_range
    offset = target_start

    return [scale, offset, inter_scale, inter_offset]

  @internal {
    source_range: [ p.Any ]
    target_range: [ p.Any ]
  }

module.exports =
  Model: LogMapper
