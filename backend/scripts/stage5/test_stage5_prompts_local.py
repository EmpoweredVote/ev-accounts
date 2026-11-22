"""pytest: stage5_prompts.py search-briefs uses the profile's search.local_subjects for local people, and falls back to
search.subjects when the profile has none. Everything runs against a temp stage5 folder; the real research folder is not read."""
import csv, json, os, subprocess, sys
import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
COLS = ['politician_id', 'full_name', 'office_id', 'level', 'state', 'scope', 'leaving', 'race_ids', 'office']
LOCAL = ['Second-Amendment-sanctuary resolutions;', 'bans on guns in city or county buildings;']
STATE = ['bans on a type of firearm;', 'background checks on gun sales;']


def build(tmp, local_subjects):
    S = tmp / 'stage5'; S.mkdir()
    prof = {'topic_key': 'gun-policy', 'label': 'x', 'research': str(tmp), 'stage5': str(S),
            'search': {'subjects': STATE, 'words': ['gun'], 'subject_examples': ['background checks']}}
    if local_subjects is not None: prof['search']['local_subjects'] = local_subjects
    (tmp / 'profile.json').write_text(json.dumps(prof))
    (S / 'coder-config.json').write_text(json.dumps({'topic_key': 'gun-policy', 'codebook': 'v1',
                                                     'ladder_text': 'Question: "What should gun law be?"\n1. a\n2. b\n'}))
    rows = [['L1', 'Lee Local', 'o1', 'local', 'UT', 'sitting', '', '', 'Mayor'], ['S1', 'Sam State', 'o2', 'state', 'UT', 'sitting', '', '', ''],
            ['F1', 'Fay Fed', 'o3', 'federal', 'UT', 'sitting', '', '', '']]
    with open(tmp / 'roster.tsv', 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t'); w.writerow(COLS); w.writerows(rows)
    return S


def brief(tmp, pid):
    (tmp / 'ids.txt').write_text(pid + '\n')
    p = subprocess.run([sys.executable, '-I', os.path.join(HERE, 'stage5_prompts.py'), 'search-briefs', '--profile', str(tmp / 'profile.json'),
                        '--state', 'ut', '--roster', str(tmp / 'roster.tsv'), '--ids', str(tmp / 'ids.txt'), '--date', '2026-11-22'],
                       capture_output=True, text=True)
    assert p.returncode == 0, p.stderr
    return open(tmp / 'stage5' / 'ut' / 'briefs' / f'{pid}.md').read()


def test_local_person_gets_local_subjects(tmp_path):
    build(tmp_path, LOCAL); text = brief(tmp_path, 'L1')
    for x in LOCAL: assert x in text
    for x in STATE: assert x not in text


def test_state_and_federal_people_keep_the_general_subjects(tmp_path):
    build(tmp_path, LOCAL)
    for pid in ('S1', 'F1'):
        text = brief(tmp_path, pid)
        for x in STATE: assert x in text
        for x in LOCAL: assert x not in text


def test_local_falls_back_when_profile_has_no_local_subjects(tmp_path):
    build(tmp_path, None); text = brief(tmp_path, 'L1')
    for x in STATE: assert x in text


def test_local_person_line_does_not_call_them_a_state_official(tmp_path):
    build(tmp_path, LOCAL); text = brief(tmp_path, 'L1')
    assert 'state official' not in text.split('Lee Local', 1)[1].split('\n', 1)[0]


def test_empty_local_subjects_fall_back(tmp_path):
    build(tmp_path, []); text = brief(tmp_path, 'L1')
    for x in STATE: assert x in text
