(function() {
  if (!document.modelContext) return;

  var bridge = {
    _queue: [],
    _resolvers: {},
    _nextId: 0,

    enqueue: function(name, args) {
      return new Promise(function(resolve) {
        var id = bridge._nextId++;
        bridge._resolvers[id] = resolve;
        bridge._queue.push({ id: id, name: name, args: args });
      });
    },

    resolve: function(id, resultJson) {
      var fn = bridge._resolvers[id];
      if (fn) {
        try { fn(JSON.parse(resultJson)); } catch (e) { fn({ error: e.message }); }
        delete bridge._resolvers[id];
      }
    },

    dequeue: function() {
      return bridge._queue.shift() || null;
    }
  };

  window.__webmcp = bridge;

  function hasTools() {
    return typeof document.modelContext !== 'undefined' && document.modelContext !== null;
  }

  function reg(name, title, desc, schema, ann) {
    if (!hasTools()) return;
    try {
      document.modelContext.registerTool({
        name: name,
        title: title,
        description: desc,
        inputSchema: schema,
        execute: function(args) { return bridge.enqueue(name, args || {}); },
        annotations: ann || {}
      });
    } catch (e) {
      console.warn('WebMCP: failed to register', name, e);
    }
  }

  reg('get_state',
    'Get Simulation State',
    'Returns current wind turbine simulation parameters, results, and UI state.',
    { type: 'object', properties: {} },
    { readOnlyHint: true });

  reg('set_parameter',
    'Set Simulation Parameter',
    'Change a simulation parameter. Keys: windSpeed (0.5-25), rotorRadius (0.1-3), cp (0.01-0.55), airDensity (0.8-1.5), tsr (0.5-10), pitchAngle (-5-20), bladeCount (2-6).',
    { type: 'object', properties: {
      key: { type: 'string', description: 'Parameter name' },
      value: { type: 'number', description: 'New value' }
    }, required: ['key', 'value'] });

  reg('set_turbine_type',
    'Set Turbine Type',
    'Switch between turbine presets: standard, high_speed, high_torque, darrieus, savonius.',
    { type: 'object', properties: {
      type: { type: 'string', 'enum': ['standard', 'high_speed', 'high_torque', 'darrieus', 'savonius'] }
    }, required: ['type'] });

  reg('toggle_pause', 'Toggle Pause', 'Pause or resume the simulation.',
    { type: 'object', properties: {} });

  reg('toggle_wireframe', 'Toggle Wireframe', 'Switch between solid and wireframe 3D rendering.',
    { type: 'object', properties: {} });

  reg('toggle_dark_mode', 'Toggle Dark Mode', 'Switch between dark and light color theme.',
    { type: 'object', properties: {} });
})();
