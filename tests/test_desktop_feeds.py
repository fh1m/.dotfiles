"""Public discovery survives offline refreshes without losing its cache."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT/'home/.local/bin'/name))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class HackerNews(unittest.TestCase):
    def test_fresh_cache_needs_no_network(self):
        m = load('sensei-nerd')
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'CACHE', Path(directory)/'nerd.json'), patch.object(m, 'hn_json') as network:
            old = {'fetchedAt': m.time.time(), 'show': [{'title':'Local cache'}], 'ask': []}
            m.CACHE.with_name('curiosity.json').write_text(json.dumps(old))
            self.assertEqual(m.curiosity(), old)
            network.assert_not_called()

    def test_offline_refresh_preserves_stories_and_success_timestamp(self):
        m = load('sensei-nerd')
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'CACHE', Path(directory)/'nerd.json'), patch.object(m, 'hn_json', side_effect=OSError('Offline')):
            old = {'fetchedAt':1, 'show':[{'title':'Saved story'}], 'ask':[{'title':'Saved question'}]}
            m.CACHE.with_name('curiosity.json').write_text(json.dumps(old))
            result = m.curiosity(True)
            self.assertEqual(result['show'], old['show'])
            self.assertEqual(result['ask'], old['ask'])
            self.assertEqual(result['fetchedAt'], 1)
            self.assertEqual(len(result['errors']), 2)
            self.assertEqual(m.CACHE.with_name('curiosity.json').stat().st_mode & 0o777, 0o600)
            self.assertFalse(list(Path(directory).glob('*.tmp-*')))

    def test_dead_stories_are_excluded_and_links_open_discussions(self):
        m = load('sensei-nerd')
        def response(endpoint):
            if endpoint.endswith('stories'):return [1,2]
            return {'id':int(endpoint.split('/')[-1]), 'title':'<plain text>', 'dead':endpoint.endswith('/2'), 'url':'https://untrusted.example'}
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'CACHE', Path(directory)/'nerd.json'), patch.object(m, 'hn_json', side_effect=response):
            result = m.curiosity(True)
            for feed in ('show', 'ask'):
                self.assertEqual(len(result[feed]), 1)
                self.assertEqual(result[feed][0]['url'], 'https://news.ycombinator.com/item?id=1')


if __name__ == '__main__':unittest.main()
