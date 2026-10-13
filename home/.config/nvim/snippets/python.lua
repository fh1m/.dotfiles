local l = require('luasnip')
local s, t, i = l.snippet, l.text_node, l.insert_node
return {
  s('rosnode', { t({ 'import rclpy', 'from rclpy.node import Node', '', '', 'class ' }), i(1, 'TelemetryNode'),
    t({ '(Node):', '    def __init__(self):', '        super().__init__("' }), i(2, 'telemetry'),
    t({ '")', '        ' }), i(0), t({ '', '', '', 'def main(args=None):', '    rclpy.init(args=args)', '    node = ' }),
    l.function_node(function(args) return args[1][1] end, { 1 }), t({ '()', '    try:', '        rclpy.spin(node)', '    finally:',
      '        node.destroy_node()', '        rclpy.shutdown()', '', '', 'if __name__ == "__main__":', '    main()' }) }),
  s('ptest', { t('def test_'), i(1, 'behavior'), t({ '():', '    # Arrange', '    ' }), i(2),
    t({ '', '    # Act', '    ' }), i(3), t({ '', '    # Assert', '    assert ' }), i(0) }),
}
