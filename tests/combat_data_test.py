"""Authoring rules must reject excess/ambiguous hurt regions before compilation."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('combat_data', ROOT / 'scripts/generate-combat-data.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class HurtboxContract(unittest.TestCase):
    def setUp(self):
        self.pose = {'hurt': {'head': [2, 0, 8, 6], 'legs': [0, 20, 10, 40], 'torsoArms': [-2, 5, 12, 24]}}

    def test_three_roles_have_stable_native_order(self):
        self.assertEqual(generator.hurt_rectangles(self.pose, 'test'), [[0, 20, 10, 40], [-2, 5, 12, 24], [2, 0, 8, 6]])

    def test_one_described_extension_is_optional(self):
        self.pose['hurt']['extension'] = [10, 10, 25, 16]
        with self.assertRaisesRegex(ValueError, 'describe'):
            generator.hurt_rectangles(self.pose, 'test')
        self.pose['extensionFor'] = 'extended punching arm'
        self.assertEqual(len(generator.hurt_rectangles(self.pose, 'test')), 4)

    def test_fifth_box_is_rejected_instead_of_dropped(self):
        self.pose['hurt'].update(extension=[10, 10, 25, 16], secondExtension=[-10, 10, 0, 16])
        self.pose['extensionFor'] = 'outstretched arms'
        with self.assertRaisesRegex(ValueError, '4 maximum'):
            generator.hurt_rectangles(self.pose, 'test')

    def test_three_boxes_cannot_omit_a_required_body_region(self):
        del self.pose['hurt']['head']
        self.pose['hurt']['extension'] = [10, 10, 25, 16]
        self.pose['extensionFor'] = 'punching arm'
        with self.assertRaisesRegex(ValueError, 'head'):
            generator.hurt_rectangles(self.pose, 'test')

    def test_every_authored_pose_follows_the_contract(self):
        data = json.loads((ROOT / 'godot/data/fighter_collision.json').read_text())
        counts = []
        for fighter in data['fighters']:
            for phase, poses in fighter['poses'].items():
                for index, pose in enumerate(poses):
                    counts.append(len(generator.hurt_rectangles(copy.deepcopy(pose), f"{fighter['name']} {phase} {index}")))
        self.assertEqual(len(counts), 194)
        self.assertEqual(set(counts), {3, 4})


if __name__ == '__main__':
    unittest.main()
