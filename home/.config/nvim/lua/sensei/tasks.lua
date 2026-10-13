local M = {}
function M.setup()
  local o = require('overseer')
  o.setup({ templates = { 'builtin' }, task_list = { direction = 'bottom', min_height = 10, max_height = 18 } })
  local root = require('sensei.environment').profile().root
  local function register(name, cmd, args, params)
    o.register_template({ name = name, params = params,
      builder = function(values)
        local resolved = type(args) == 'function' and args(values or {}) or args
        return { cmd = type(cmd) == 'function' and cmd() or cmd, args = resolved, cwd = root,
          components = { { 'on_output_quickfix', open = false, set_diagnostics = false }, 'default' } }
      end })
  end
  register('Python: current file', require('sensei.environment').python, function() return { vim.api.nvim_buf_get_name(0) } end)
  register('Python: project tests', require('sensei.environment').python, { '-m', 'pytest', '-q' })
  if vim.fn.executable('colcon') == 1 and vim.uv.fs_stat(root .. '/src') then
    local package = { package = { type = 'string', desc = 'Exact ROS package name (no shell flags)' } }
    register('ROS: build selected package', 'colcon', function(v)
      assert(v.package:match('^[%w_]+$'), 'Use one package name')
      return { 'build', '--packages-select', v.package, '--parallel-workers', '2', '--cmake-args', '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON' }
    end, package)
    register('ROS: test selected package', 'colcon', function(v)
      assert(v.package:match('^[%w_]+$'), 'Use one package name')
      return { 'test', '--packages-select', v.package, '--parallel-workers', '2' }
    end, package)
    register('ROS: test results', 'colcon', { 'test-result', '--verbose' })
    register('ROS: inspect interface', 'ros2', function(v)
      assert(v.interface:match('^[%w_]+/[%w_]+/[%w_]+$'), 'Use package/msg/Name or package/srv/Name')
      return { 'interface', 'show', v.interface }
    end, { interface = { type = 'string', desc = 'package/msg/Name' } })
    local host = vim.env.SENSEI_HOST_HOME or vim.fn.expand('~')
    register('C++: refresh compile database from existing builds', host .. '/.local/bin/sensei-dev', { 'compile-db', root })
  end
  if vim.uv.fs_stat(root .. '/CMakeLists.txt') then
    register('CMake: configure debug build', 'cmake', { '-S', root, '-B', root .. '/build', '-DCMAKE_BUILD_TYPE=Debug', '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON' })
    register('CMake: build', 'cmake', { '--build', root .. '/build', '--parallel', '2' })
    register('CMake: test', 'ctest', { '--test-dir', root .. '/build', '--output-on-failure' })
  end
end
return M
