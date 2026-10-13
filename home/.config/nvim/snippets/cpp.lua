local l = require('luasnip')
local s, t, i = l.snippet, l.text_node, l.insert_node
return {
  s('rosnode', { t({ '#include <memory>', '#include "rclcpp/rclcpp.hpp"', '', 'class ' }), i(1, 'TelemetryNode'),
    t({ ' : public rclcpp::Node {', 'public:', '  ' }), l.function_node(function(a) return a[1][1] end, {1}),
    t('() : Node("'), i(2, 'telemetry'), t({ '") {', '    ' }), i(0), t({ '', '  }', '};', '',
      'int main(int argc, char** argv) {', '  rclcpp::init(argc, argv);', '  rclcpp::spin(std::make_shared<' }),
    l.function_node(function(a) return a[1][1] end, {1}), t({ '>());', '  rclcpp::shutdown();', '  return 0;', '}' }) }),
  s('contract', { t({ '/**', ' * @brief ' }), i(1, 'What this operation guarantees.'),
    t({ '', ' * Units/frame: ' }), i(2, 'SI / body frame'), t({ '', ' * Preconditions: ' }), i(3),
    t({ '', ' * Failure behavior: ' }), i(0), t({ '', ' */' }) }),
}
