import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'home/.local/share/sensei-learning'))
from noesis.presentation import preview


class NativeReading(unittest.TestCase):
    def test_formatting_is_generated_and_source_html_cannot_load_content(self):
        blocks = preview('## **Objective**\n\n**Predict** a *changed case* with `x < 2`.\n\n<script>bad()</script>\n![remote](https://invalid.example/pixel)')['blocks']
        self.assertEqual(blocks[0]['html'], '<b>Objective</b>')
        self.assertEqual(blocks[1]['html'], '<b>Predict</b> a <i>changed case</i> with <code>x &lt; 2</code>.')
        self.assertEqual(blocks[2]['display_text'], 'HTML content · open the complete note')
        rendered = ''.join(block.get('html', block.get('display_text', block['text'])) for block in blocks)
        self.assertNotIn('<script>', rendered)
        self.assertNotIn('<img', rendered)
        self.assertNotIn('https://', rendered)

    def test_task_lists_preserve_nested_levels_and_numbered_labels(self):
        blocks = preview('- [ ] Predict\n  - [x] Check\n\n3. Changed case\n4. Return')['blocks']
        self.assertEqual(blocks[0]['text'], '☐ Predict\n  ☑ Check')
        self.assertIn('&#160;&#160;☑ Check', blocks[0]['html'])
        self.assertEqual(blocks[1]['text'], '3. Changed case\n4. Return')

    def test_table_and_specialist_material_have_explicit_rendering_contracts(self):
        result = preview('| Case | Result |\n| --- | --- |\n| Zero | 3 |\n\n$$\nx=\\alpha\n$$\n\n```mermaid\ngraph LR; A-->B\n```')
        self.assertEqual(result['blocks'][0]['columns'], ['Case', 'Result'])
        self.assertEqual(result['blocks'][0]['rows'], [['Zero', '3']])
        table = preview('| **Case** | Result |\n| --- | --- |\n| `x < 2` | <img src="remote"> |')['blocks'][0]
        self.assertEqual(table['columns_html'][0], '<b>Case</b>')
        self.assertEqual(table['rows_html'][0][0], '<code>x &lt; 2</code>')
        self.assertNotIn('<img', table['rows_html'][0][1])
        rendered=' '.join(block.get('display_text',block['text']) for block in result['blocks'])
        self.assertNotIn('\\alpha', rendered)
        self.assertNotIn('graph LR', rendered)
        self.assertIn('Equation', rendered)
        self.assertIn('Diagram', rendered)
        self.assertEqual(set(result['specialist_features']), {'mathematics', 'diagrams'})

    def test_executable_code_is_read_only_verbatim_not_interpreted_as_markup(self):
        code = '<img src="https://invalid.example">\n**literal**'
        block = preview('```python\n'+code+'\n```')['blocks'][0]
        self.assertEqual(block['kind'], 'code')
        self.assertEqual(block['language'], 'python')
        self.assertEqual(block['text'], code)
        self.assertNotIn('html', block)
