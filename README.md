Loom
========
[![Build Status](https://travis-ci.org/asonge/loom.svg?branch=master)](https://travis-ci.org/asonge/loom)
[![Coverage Status](https://coveralls.io/repos/asonge/loom/badge.svg?branch=master)](https://coveralls.io/r/asonge/loom?branch=master)
[![Docs Status](http://inch-ci.org/github/asonge/loom.svg?branch=master)](http://inch-ci.org/github/asonge/loom)
[![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg)](https://hexdocs.pm/loom)
[![Current Release](https://img.shields.io/hexpm/v/loom.svg)](https://hex.pm/packages/loom)
![License Apache2](https://img.shields.io/hexpm/l/loom.svg)

Loom is a set of basic CRDT's that are designed to be composable and extensible.
We include support for delta-CRDT's (δ-CRDT's) where it makes sense.

## δ-CRDT's ##

In order to combat issues with large objects, δ-CRDT's are supported for some
datatypes. You can extract deltas from delta-CRDT's, and periodically clear them
out from your datastructures to reduce memory constraints.

## What the heck is a CRDT? ##
Conflict-free, Coordination-free, Commutative, or Convergent datatypes, CRDT's
are usually formally described as "join semi-lattices". Mathematical jargon
aside, CRDT's track causality for modifications to your data. Because of this,
time becomes less relevant, and coordination becomes unnecessary to get accurate
values for your data.

## Can you give me an example of one? ##
I will have a simple explanation here for a basic gcounter and a pncounter.

For now, I can simply point you to the GCounter code in here.

## Where can I learn more? ##
*   Strong Eventual Consistency and Conflict-free Replicated Data Types
    *   A good introduction to the concept of CRDTs: http://research.microsoft.com/apps/video/default.aspx?id=153540&r=1
*   A comprehensive study of Convergent and Commutative Replicated Data Types
    *   A survey with references for several popular CRDTs: http://hal.inria.fr/docs/00/55/55/88/PDF/techreport.pdf
*   Efficient State-based CRDTs by Delta-Mutation
    *   Talk: https://www.youtube.com/watch?v=y_ewFP-lgyM
    *   Paper: http://arxiv.org/pdf/1410.2803v1.pdf
