"""Builds the RapidStart packages with the demo data of the Project Billing Agent.

    python tools/build_demo_packages.py [output folder]

Writes four packages (gzip, UTF-16 XML, as Business Central exports them) to demo/ or the given folder. Apply them in
this order with tools/Import-DemoData.ps1, after the app is installed (the projects use its fields):

  PBA-1-SETUP     unit of measure PERCENT, project journal batch PROJECT/BILLING
  PBA-2-MASTER    resources and customers
  PBA-3-PROJECTS  four projects with tasks, budget lines and the fixed price milestones
  PBA-4-USAGE     the project journal lines (usage) for September and October; post them in the journal

All names are fictional (CRONUS US style). The company must have the CRONUS US sample data: posting groups DOMESTIC
and SERVICES, tax groups, project posting group SETTING UP and the journal template PROJECT.
"""
import gzip
import os
import re
import sys
from xml.sax.saxutils import escape

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', 'demo')


def element_name(field):
    return re.sub(r'[^A-Za-z0-9_]', '', field.replace('-', '_'))


def table_xml(table_name, table_id, fields, rows):
    """fields: list of (field name, kind) with kind 'pk', 'v' (validated) or '' (written as is)."""
    tag = element_name(table_name)
    parts = [f'<{tag}List><TableID>{table_id}</TableID>']
    for index, row in enumerate(rows):
        parts.append(f'<{tag}>')
        for (field, kind), value in zip(fields, row):
            name = element_name(field)
            attr = ''
            if index == 0 and kind == 'pk':
                attr = ' PrimaryKey="1"'
            elif index == 0 and kind == 'v':
                attr = ' ValidateField="1"'
            parts.append(f'<{name}{attr}>{escape(str(value))}</{name}>')
        parts.append(f'</{tag}>')
    parts.append(f'</{tag}List>')
    return ''.join(parts)


def write_package(code, name, tables):
    xml = ('<?xml version="1.0" encoding="UTF-16" standalone="yes"?>'
           f'<DataList MinCountForAsyncImport="10000" ProductVersion="" PackageName="{escape(name)}" Code="{code}">'
           + ''.join(tables) + '</DataList>')
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f'{code}.rapidstart')
    with gzip.open(path, 'wb') as f:
        f.write(xml.encode('utf-16'))
    print(path)


# --- 1. Setup -------------------------------------------------------------------------------------------------------
write_package('PBA-1-SETUP', 'Project Billing Agent demo - 1 setup', [
    table_xml('Unit of Measure', 204,
              [('Code', 'pk'), ('Description', 'v')],
              [('PERCENT', 'Percent of the fixed price')]),
    table_xml('Job Journal Batch', 237,
              [('Journal Template Name', 'pk'), ('Name', 'pk'), ('Description', 'v')],
              [('PROJECT', 'BILLING', 'Usage for the billing demo')]),
])

# --- 2. Resources and customers -------------------------------------------------------------------------------------
write_package('PBA-2-MASTER', 'Project Billing Agent demo - 2 resources and customers', [
    table_xml('Resource', 156,
              [('No.', 'pk'), ('Type', 'v'), ('Name', 'v'), ('Base Unit of Measure', 'v'), ('Direct Unit Cost', 'v'),
               ('Unit Cost', 'v'), ('Unit Price', 'v'), ('Gen. Prod. Posting Group', 'v'), ('Tax Group Code', 'v')],
              [('R-CONSULT', 0, 'Consultant hour', 'HOUR', 75, 75, 150, 'SERVICES', 'LABOR'),
               ('R-DEV', 0, 'Developer hour', 'HOUR', 70, 70, 140, 'SERVICES', 'LABOR'),
               ('R-PM', 0, 'Project manager hour', 'HOUR', 80, 80, 160, 'SERVICES', 'LABOR'),
               # Fixed price milestones are entered as a share of the fixed price of PRJ-2001: 1 % = 400 USD.
               ('R-MILESTONE', 0, 'Fixed price share (1 % of 40,000)', 'PERCENT', 0, 0, 400, 'SERVICES', 'LABOR')]),
    table_xml('Customer', 18,
              [('No.', 'pk'), ('Name', 'v'), ('Address', 'v'), ('City', 'v'), ('Customer Posting Group', 'v'),
               ('Language Code', 'v'), ('Country/Region Code', 'v'), ('Gen. Bus. Posting Group', 'v'), ('Post Code', 'v'),
               ('County', 'v'), ('Tax Area Code', 'v'), ('Tax Liable', 'v'), ('Payment Terms Code', 'v')],
              [('C91010', 'Fabrikam Retail', '400 Lake Shore Drive', 'Chicago', 'DOMESTIC', 'ENU', 'US', 'DOMESTIC',
                '61236', 'IL', 'CHICAGO, IL', 1, '30 DAYS'),
               ('C91020', 'Tailspin Manufacturing', '20 Harbor Road', 'Atlanta', 'DOMESTIC', 'ENU', 'US', 'DOMESTIC',
                '31772', 'GA', 'ATLANTA, GA', 1, '30 DAYS'),
               ('C91030', 'Proseware, Inc.', '7 Bay Street', 'Miami', 'DOMESTIC', 'ENU', 'US', 'DOMESTIC',
                '37125', 'FL', 'MIAMI, FL', 1, '30 DAYS')]),
])

# --- 3. Projects ----------------------------------------------------------------------------------------------------
FABRIKAM_NOTES = ('Time and material, invoiced monthly at the resource rates. Warranty work and rework of delivered '
                  'features are not billed. Travel time is not billed. Invoice cap (not to exceed): 11,500 USD.')
TRAINING_NOTES = ('Time and material, invoiced monthly. Training hours are billed at the consultant rate. Course material '
                  'is included in the price.')
TAILSPIN_NOTES = ('Fixed price 40,000 USD in three milestones: 30 % at design sign-off, 50 % at go-live, 20 % after four '
                  'weeks of hypercare. Hours are not billed separately.')
PROSEWARE_NOTES = 'Time and material, invoiced monthly at the resource rates.'

jobs = [
    # No., Description, Sell-to (also Bill-to: RapidStart does not fill it from Sell-to), Posting group, Status (2 = Open), Starting, Ending, Billing method, Cap, Notes
    ('PRJ-1001', 'Fabrikam POS rollout support', 'C91010', 'SETTING UP', 2, '2026-09-01', '2026-12-31', 1, 11500, FABRIKAM_NOTES),
    ('PRJ-1002', 'Fabrikam store manager training', 'C91010', 'SETTING UP', 2, '2026-09-01', '2026-10-31', 1, 0, TRAINING_NOTES),
    ('PRJ-2001', 'Tailspin warehouse redesign', 'C91020', 'SETTING UP', 2, '2026-08-17', '2026-12-18', 2, 40000, TAILSPIN_NOTES),
    ('PRJ-3001', 'Proseware finance health check', 'C91030', 'SETTING UP', 2, '2026-10-01', '2026-10-31', 1, 0, PROSEWARE_NOTES),
]
tasks = [
    # Job, Task, Description, Type (0 = Posting), Posting group, Milestone reached, Reached date
    ('PRJ-1001', '1010', 'Consulting', 0, 'SETTING UP', 0, ''),
    ('PRJ-1001', '1020', 'Development', 0, 'SETTING UP', 0, ''),
    ('PRJ-1001', '1030', 'Project management', 0, 'SETTING UP', 0, ''),
    ('PRJ-1002', '1010', 'Training', 0, 'SETTING UP', 0, ''),
    ('PRJ-2001', '100', 'Design', 0, 'SETTING UP', 1, '2026-09-18'),
    ('PRJ-2001', '200', 'Go-live', 0, 'SETTING UP', 0, ''),
    ('PRJ-2001', '300', 'Hypercare', 0, 'SETTING UP', 0, ''),
    ('PRJ-3001', '1010', 'Health check', 0, 'SETTING UP', 0, ''),
]
BUDGET, BILLABLE = 0, 1
planning = [
    # Job, Task, Line, Date, Line type, Type (0 = Resource), No., Description, Quantity, Unit of measure
    ('PRJ-1001', '1010', 10000, '2026-09-01', BUDGET, 0, 'R-CONSULT', 'Consulting, budget', 60, 'HOUR'),
    ('PRJ-1001', '1020', 10000, '2026-09-01', BUDGET, 0, 'R-DEV', 'Development, budget', 60, 'HOUR'),
    ('PRJ-1001', '1030', 10000, '2026-09-01', BUDGET, 0, 'R-PM', 'Project management, budget', 10, 'HOUR'),
    ('PRJ-1002', '1010', 10000, '2026-09-01', BUDGET, 0, 'R-CONSULT', 'Training, budget', 16, 'HOUR'),
    ('PRJ-2001', '100', 10000, '2026-08-17', BUDGET, 0, 'R-CONSULT', 'Design, budget', 80, 'HOUR'),
    ('PRJ-2001', '100', 20000, '2026-09-15', BILLABLE, 0, 'R-MILESTONE', 'Milestone 1: design sign-off (30 %)', 30, 'PERCENT'),
    ('PRJ-2001', '200', 10000, '2026-09-01', BUDGET, 0, 'R-DEV', 'Go-live, budget', 120, 'HOUR'),
    ('PRJ-2001', '200', 20000, '2026-09-30', BILLABLE, 0, 'R-MILESTONE', 'Milestone 2: go-live (50 %)', 50, 'PERCENT'),
    ('PRJ-2001', '300', 10000, '2026-11-01', BUDGET, 0, 'R-CONSULT', 'Hypercare, budget', 40, 'HOUR'),
    ('PRJ-2001', '300', 20000, '2026-11-30', BILLABLE, 0, 'R-MILESTONE', 'Milestone 3: end of hypercare (20 %)', 20, 'PERCENT'),
    ('PRJ-3001', '1010', 10000, '2026-10-01', BUDGET, 0, 'R-CONSULT', 'Health check, budget', 24, 'HOUR'),
]
write_package('PBA-3-PROJECTS', 'Project Billing Agent demo - 3 projects, tasks and planning lines', [
    table_xml('Job', 167,
              [('No.', 'pk'), ('Description', 'v'), ('Sell-to Customer No.', 'v'), ('Bill-to Customer No.', 'v'), ('Job Posting Group', 'v'),
               ('Status', ''), ('Starting Date', 'v'), ('Ending Date', 'v'), ('PBA Billing Method', 'v'),
               ('PBA Invoice Cap', 'v'), ('PBA Billing Notes', 'v')],
              [job[:3] + (job[2],) + job[3:] for job in jobs]),
    table_xml('Job Task', 1001,
              [('Job No.', 'pk'), ('Job Task No.', 'pk'), ('Description', 'v'), ('Job Task Type', 'v'),
               ('Job Posting Group', 'v'), ('PBA Milestone Reached', 'v'), ('PBA Milestone Reached Date', 'v')],
              tasks),
    table_xml('Job Planning Line', 1003,
              [('Job No.', 'pk'), ('Job Task No.', 'pk'), ('Line No.', 'pk'), ('Planning Date', 'v'), ('Line Type', 'v'),
               ('Type', 'v'), ('No.', 'v'), ('Description', 'v'), ('Quantity', 'v'), ('Unit of Measure Code', 'v')],
              planning),
])

# --- 4. Usage -------------------------------------------------------------------------------------------------------
NONE, JNL_BILLABLE = 0, 2
usage = [
    # Line, Posting date, Document, Job, Task, Type, No., Description, Quantity, Line type
    (10000, '2026-09-03', 'USAGE-2609', 'PRJ-1001', '1010', 0, 'R-CONSULT', 'Store process workshops', 16, JNL_BILLABLE),
    (20000, '2026-09-08', 'USAGE-2609', 'PRJ-2001', '100', 0, 'R-CONSULT', 'Warehouse layout design', 40, NONE),
    (30000, '2026-09-10', 'USAGE-2609', 'PRJ-1001', '1010', 0, 'R-CONSULT', 'POS configuration, pilot store', 24, JNL_BILLABLE),
    (40000, '2026-09-15', 'USAGE-2609', 'PRJ-1001', '1020', 0, 'R-DEV', 'Loyalty points interface', 30, JNL_BILLABLE),
    (50000, '2026-09-17', 'USAGE-2609', 'PRJ-1001', '1010', 0, 'R-CONSULT', 'Travel to the Chicago pilot store', 6, JNL_BILLABLE),
    (60000, '2026-09-21', 'USAGE-2609', 'PRJ-2001', '200', 0, 'R-DEV', 'Scanner app prototype', 24, NONE),
    (70000, '2026-09-22', 'USAGE-2609', 'PRJ-1002', '1010', 0, 'R-CONSULT', 'Training, store managers group 1', 8, JNL_BILLABLE),
    (80000, '2026-09-24', 'USAGE-2609', 'PRJ-1001', '1020', 0, 'R-DEV', 'Rework of the receipt layout after go-live (warranty)', 8, JNL_BILLABLE),
    (90000, '2026-09-25', 'USAGE-2609', 'PRJ-1001', '1030', 0, 'R-PM', 'Steering committee, September', 4, JNL_BILLABLE),
    (100000, '2026-09-29', 'USAGE-2609', 'PRJ-1001', '1020', 0, 'R-DEV', 'Gift card extension', 10, JNL_BILLABLE),
    (110000, '2026-10-02', 'USAGE-2610', 'PRJ-3001', '1010', 0, 'R-CONSULT', 'Health check interviews', 12, JNL_BILLABLE),
    (120000, '2026-10-06', 'USAGE-2610', 'PRJ-1001', '1010', 0, 'R-CONSULT', 'Second store rollout', 8, JNL_BILLABLE),
    (130000, '2026-10-07', 'USAGE-2610', 'PRJ-1002', '1010', 0, 'R-CONSULT', 'Training, store managers group 2', 8, JNL_BILLABLE),
]
write_package('PBA-4-USAGE', 'Project Billing Agent demo - 4 usage to post (project journal PROJECT/BILLING)', [
    table_xml('Job Journal Line', 210,
              [('Journal Template Name', 'pk'), ('Journal Batch Name', 'pk'), ('Line No.', 'pk'), ('Posting Date', 'v'),
               ('Document No.', 'v'), ('Job No.', 'v'), ('Job Task No.', 'v'), ('Type', 'v'), ('No.', 'v'),
               ('Description', 'v'), ('Quantity', 'v'), ('Line Type', 'v')],
              [('PROJECT', 'BILLING') + row for row in usage]),
])
