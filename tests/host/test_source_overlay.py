"""Pinned Git sources, layered patches and cache rejection; no FPGA tools needed."""
import difflib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools/build'))
import source_overlay as overlay


class SourceOverlay(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.base = self.repo / 'baseline'
        self.base.mkdir()
        (self.base / 'Main.scala').write_text('val depth = 8\n')
        (self.base / 'resource.bin').write_bytes(bytes(range(256)))
        (self.base / 'nested').mkdir()
        (self.base / 'nested/Helper.scala').write_text('class Helper\n')
        self.git('init', '-q')
        self.git('add', 'baseline')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'baseline')
        self.commit = self.git('rev-parse', 'HEAD')
        self.files = overlay.tree_hashes(self.base)
        self.version = self.repo / 'hw/versions/fifo16'
        self.version.mkdir(parents=True)
        base = dict(kind='git', commit=self.commit, directory='baseline',
                    tree=self.git('rev-parse', self.commit + ':baseline'), files_sha256=self.files)
        self.recipe = self.layer(self.version, base, 'val depth = 8\n', 'val depth = 16\n', self.files)

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args], text=True, stderr=subprocess.DEVNULL).strip()

    def write(self, path, data):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, indent=2) + '\n')

    def layer(self, version, base, before, after, original):
        patch = version / 'patches/main.patch'
        patch.parent.mkdir(parents=True, exist_ok=True)
        patch.write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                                    fromfile='a/Main.scala', tofile='b/Main.scala')))
        import hashlib
        after_sha = hashlib.sha256(after.encode()).hexdigest()
        files = dict(original, **{'Main.scala': after_sha})
        recipe = dict(schema=1, base=base, patches=[dict(file='patches/main.patch', sha256=overlay.sha(patch))],
                      overlay={}, changes={'Main.scala': dict(before=original['Main.scala'], after=after_sha)},
                      effective_tree_sha256=overlay.digest_map(files))
        self.write(version / 'manifests/SOURCE_OVERLAY.json', recipe)
        return recipe

    def test_pinned_commit_ignores_modified_baseline_worktree(self):
        (self.base / 'Main.scala').write_text('uncommitted unrelated changes\n')
        result = overlay.prepare(self.version, self.repo)
        self.assertEqual((result.root / 'Main.scala').read_text(), 'val depth = 16\n')
        self.assertEqual((result.root / 'resource.bin').read_bytes(), bytes(range(256)))
        self.assertEqual((self.base / 'Main.scala').read_text(), 'uncommitted unrelated changes\n')
        self.assertTrue(result.root.is_relative_to(self.version / 'build'))
        self.assertEqual(overlay.prepare(self.version, self.repo).root, result.root)

    def test_changed_patch_is_rejected(self):
        (self.version / 'patches/main.patch').write_text('changed')
        with self.assertRaisesRegex(ValueError, 'patch/overlay changed'):
            overlay.prepare(self.version, self.repo)

    def test_default_repository_root_accepts_hw_versions_layout(self):
        result = overlay.prepare(self.version)
        self.assertEqual((result.root / 'Main.scala').read_text(), 'val depth = 16\n')
        self.assertTrue(result.root.is_relative_to(self.version / 'build'))

    def test_relocation_preserves_effective_sources_and_cache_identity(self):
        prepared = overlay.prepare(self.version)
        destination = self.repo / 'hw/versions/relocated_fifo16'
        self.version.rename(destination)
        relocated = overlay.prepare(destination)
        self.assertEqual(relocated.files, prepared.files)
        self.assertEqual(relocated.recipe_sha256, prepared.recipe_sha256)
        self.assertEqual((relocated.root / 'Main.scala').read_text(), 'val depth = 16\n')

    def test_changed_index_does_not_replace_the_pinned_commit(self):
        (self.base / 'Main.scala').write_text('val depth = 99\n')
        self.git('add', 'baseline/Main.scala')
        result = overlay.prepare(self.version, self.repo)
        self.assertEqual((result.root / 'Main.scala').read_text(), 'val depth = 16\n')
        self.assertEqual((self.base / 'Main.scala').read_text(), 'val depth = 99\n')

    def test_wrong_git_tree_is_rejected(self):
        self.recipe['base']['tree'] = '0' * 40
        self.write(self.version / 'manifests/SOURCE_OVERLAY.json', self.recipe)
        with self.assertRaisesRegex(ValueError, 'Git tree mismatch'):
            overlay.prepare(self.version, self.repo)

    def test_wrong_patch_preimage_is_rejected(self):
        self.recipe['changes']['Main.scala']['before'] = '0' * 64
        self.write(self.version / 'manifests/SOURCE_OVERLAY.json', self.recipe)
        with self.assertRaisesRegex(ValueError, 'preimage mismatch'):
            overlay.prepare(self.version, self.repo)

    def test_cache_content_changes_are_rejected(self):
        result = overlay.prepare(self.version, self.repo)
        (result.root / 'Main.scala').write_text('changed cache')
        with self.assertRaisesRegex(ValueError, 'cache changed'):
            overlay.prepare(self.version, self.repo)

    def test_cache_extra_files_are_rejected(self):
        result = overlay.prepare(self.version, self.repo)
        (result.root / 'unexpected.scala').write_text('not in the recipe')
        with self.assertRaisesRegex(ValueError, 'cache changed'):
            overlay.prepare(self.version, self.repo)

    def test_second_layer_and_new_source_have_complete_inventory(self):
        parent = overlay.prepare(self.version, self.repo)
        team = self.repo / 'hw/versions/team'
        team.mkdir(parents=True)
        base = dict(kind='version', directory=str(self.version.relative_to(self.repo)),
                    manifest_sha256=overlay.sha(self.version / 'manifests/SOURCE_OVERLAY.json'))
        recipe = self.layer(team, base, 'val depth = 16\n', 'val depth = 16 // DirectA\n', parent.files)
        addition = team / 'overlay/S1MvinLanePlace.scala'
        addition.parent.mkdir()
        addition.write_text('class S1MvinLanePlace\n')
        recipe['overlay']['S1MvinLanePlace.scala'] = dict(file='overlay/S1MvinLanePlace.scala', sha256=overlay.sha(addition))
        recipe['changes']['S1MvinLanePlace.scala'] = dict(before=None, after=overlay.sha(addition))
        expected = dict(parent.files, **{n: c['after'] for n, c in recipe['changes'].items()})
        recipe['effective_tree_sha256'] = overlay.digest_map(expected)
        self.write(team / 'manifests/SOURCE_OVERLAY.json', recipe)
        result = overlay.prepare(team, self.repo)
        self.assertEqual(result.files, expected)
        self.assertEqual((parent.root / 'Main.scala').read_text(), 'val depth = 16\n')
        self.recipe['description'] = 'new parent recipe'
        self.write(self.version / 'manifests/SOURCE_OVERLAY.json', self.recipe)
        with self.assertRaisesRegex(ValueError, 'Pinned parent source recipe changed'):
            overlay.prepare(team, self.repo)

    def test_unsafe_recipe_paths_are_rejected(self):
        for name in ('../other', '/tmp/other', 'a/../../other', 'a\\other'):
            with self.assertRaises(ValueError):overlay.relative(name)

    def test_recorded_artifact_allows_only_exact_recipe_migration(self):
        prepared = overlay.prepare(self.version, self.repo)
        old = {'source/chipyard/Main.scala': prepared.files['Main.scala'], 'scripts/generate.py': 'old'}
        current = dict(old, **{'scripts/generate.py': 'new'})
        context = self.version / 'generated/GENERATION_CONTEXT.json'
        self.write(context, dict(dma_load_build_id='0123456789abcdef', source_identity_sha256='original',
                                 build_inputs_sha256=old))
        entry = dict(hardware_build_id='0123456789abcdef', effective_tree_sha256=overlay.digest_map(prepared.files),
                     original_build_inputs_sha256=old, recipe_changes=overlay.input_changes(old, current))
        self.write(self.version / 'manifests/SOURCE_LAYOUT_MIGRATION.json',
                   dict(artifacts={overlay.sha(context): entry}))
        self.assertEqual(overlay.verify_recorded_artifact(self.version, context, current, prepared), 'original')
        with self.assertRaisesRegex(ValueError, 'recipe differs'):
            overlay.verify_recorded_artifact(self.version, context, dict(current, **{'scripts/generate.py': 'unexpected'}), prepared)
        changed = dict(current, **{'source/chipyard/Main.scala': 'different RTL source'})
        with self.assertRaisesRegex(ValueError, 'Non-recipe input changed'):
            overlay.verify_recorded_artifact(self.version, context, changed, prepared)

    def test_changed_historical_context_is_not_accepted(self):
        prepared = overlay.prepare(self.version, self.repo)
        context = self.version / 'generated/GENERATION_CONTEXT.json'
        self.write(context, dict(dma_load_build_id='0123456789abcdef'))
        self.write(self.version / 'manifests/SOURCE_LAYOUT_MIGRATION.json', dict(artifacts={}))
        with self.assertRaisesRegex(ValueError, 'not recorded'):
            overlay.verify_recorded_artifact(self.version, context, {}, prepared)


if __name__ == '__main__':
    unittest.main()
