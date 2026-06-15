# Technical Report

> institution: [Universidade]

> faculty: [Instituto / Faculdade]

> department: [Laboratório / Programa] — Relatórios Técnicos — RT-[NÚMERO]

> course: [Programa de Pós-Graduação]

> title: A Relational Intermediate Representation and Compiler Infrastructure for Structural Verification of Textual Specifications

> author: Cristiano Lacerda

> advisor: Prof. Dr. José Carlos Maldonado

> nature: Relatório Técnico

> city: [Cidade]

> year: 2026

## Cover

## Title Page

## Abstract

Textual specifications written in natural language remain central artifacts in software engineering, especially in environments where documents must serve as auditable evidence. In practice, however, many review findings are not about interpretation of domain intent, but about structure: invalid identifiers, missing mandatory attributes, unresolved references, inconsistent traceability, or malformed generated views. This report presents SpecDown and SpecCompiler, together with Spec-IR, a relational intermediate representation persisted in SQLite for compiling and structurally verifying such documents. The approach is deliberately conservative. It does not claim to verify the intended system behavior described by the prose; instead, it checks whether a document conforms to a declared type system of specification types, object types, floats, attributes, relations, and views. The report describes the Spec-IR schema, the current type system that defines the authoring language, the five-phase compilation pipeline, and the use of SQL proof views as executable structural constraints. The result is a practical infrastructure for compile-time verification of textual specifications before review-oriented deliverables such as DOCX or HTML are emitted.

## Table of Contents

`select: toc`

## Introduction

In regulated and review-intensive software development, specifications are not merely explanatory prose. They are process artifacts that must remain complete, consistent, traceable, and inspectable across revisions. Yet conventional document toolchains treat them primarily as formatting inputs. As a consequence, many defects that are straightforward to characterize structurally are detected late: broken references, ambiguous links, missing mandatory metadata, invalid attribute values, absent coverage relations, and rendering failures in generated content.

SpecDown adopts a compiler-oriented view of specification authoring. Documents are written in Markdown using a controlled set of conventions, parsed into a Pandoc `sigla: Abstract Syntax Tree (AST)`, lowered by SpecCompiler into `sigla: Specification Intermediate Representation (Spec-IR)`, and checked against a loaded type system before any deliverable is emitted. The central claim of this report is therefore limited and technical: specifications can be verified with respect to a declared class of structural obligations.

This report uses the term **type-safe** in that restricted sense [cardelli1996;pierce2002](@cite). A specification is considered well-typed when it contains none of the structural violations captured by the configured proof views. This excludes an important class of review defects, while leaving linguistic adequacy, engineering judgment, and behavioral intent to human analysis.

### Scope and contributions

The design targets the following goals:

1. **Plain-text sources**: specifications authored in Markdown with minimal additional conventions and versioned with Git.
2. **Model-defined language**: the accepted object kinds, attributes, relations, floats, and views are defined by a loaded type system rather than hard-coded per document.
3. **Persistent IR**: a queryable intermediate representation stored in SQLite for reproducible checking and reporting.
4. **Declarative verification**: structural constraints expressed as SQL views that enumerate counterexamples.
5. **Verified emission**: output generation allowed only after structural verification succeeds.

This report makes the following contributions:

1. **Spec-IR**: a relational IR for textual specifications that complements the Pandoc AST with typed, queryable content tables.
2. **A conservative verification scope**: a precise separation between structural verification and evaluation of document content.
3. **A compiler account of the current language**: an explanation of how the active SpecCompiler type system defines the authoring language used in practice.
4. **Executable structural checking**: a proof-view framework in which violations are materialized as SQL result sets over the compiled IR.

### Architecture overview

The overall structure follows a conventional compiler decomposition [aho2006;lattner2002](@cite). Pandoc provides the reader and writer [pandoc](@cite); SpecCompiler acts as the middle-end as a Pandoc Lua filter; Spec-IR in SQLite is the persistent verification substrate [sqlite](@cite). The compilation flow is deterministic and phase-structured.

Operationally, the system proceeds as follows:

1. **Model loading**: load the active type modules and register them in the type-system tables.
2. **INITIALIZE**: lower the Pandoc AST into content tables for specifications, objects, attributes, floats, relations, and views.
3. **ANALYZE**: resolve references, infer relation types, and cast attribute values against declared datatypes.
4. **TRANSFORM**: materialize generated views, render external artifacts, assign numbering, and rewrite links in the reconstructed AST.
5. **VERIFY**: execute proof views and collect violations.
6. **EMIT**: invoke Pandoc writers only if verification reports no error-level diagnostics.

Within each phase, handlers are ordered by declared prerequisites using a topological sort. This keeps the pipeline extensible while preserving deterministic behavior across runs.

### Core entities and relations

Spec-IR stores the following first-class entities:

- **Specifications**: root documents such as SRS, SDD, SVC, or TRR.
- **Objects**: typed document units such as sections, requirements, verification cases, or design elements.
- **Attributes**: typed metadata attached to specifications, objects, or floats.
- **Relations**: typed links between objects and floats.
- **Floats**: numbered elements such as figures, tables, listings, diagrams, and equations.
- **Views**: generated blocks such as tables of contents, traceability matrices, or result matrices.

### A minimal complete example

The concrete syntax remains close to ordinary Markdown, but the active type system gives selected constructs a typed interpretation. The running example below uses a `default + sw_docs` stack because it makes typed relations and proof views explicit:

```src.md:rtf-mini-example{caption="Example using a default plus sw_docs model stack"}
# SRS: Login Service

> version: 0.1

> status: Draft

> date: 2026-03-22

## HLR: Authenticate Users @HLR-013

The system shall authenticate users via OAuth 2.0.

> status: Draft

> priority: High

> rationale: Protect access to user data.

` ` `puml:dataflow{caption="Compilation flow"}
@startuml
[Markdown] --> [Spec-IR] --> [DOCX/HTML]
@enduml
` ` `

## VC: Verify Authentication @VC-002

Verify the authentication flow works end to end.

> objective: Confirm OAuth 2.0 login succeeds.

> verification_method: Test

> traceability: [HLR-013](@)

### Test Results

`test_results_matrix:`
```

Under that model stack, this source yields one specification record, two object records, typed attributes, one float, one inferred `VERIFIES` relation, and one generated view.

```list-table:rtf-syntax-to-ir{caption="From current source syntax to Spec-IR"}
> header-rows: 1
> aligns: l,l,l

* - Source construct
  - Example syntax
  - Spec-IR target
* - Specification root
  - `# SRS: Login Service`
  - `specifications`
* - Typed objects
  - `## HLR: Authenticate Users @HLR-013`
  - `spec_objects`
* - Typed attributes
  - `> priority: High`
  - `spec_attribute_values`
* - Floats
  - `` ```puml:dataflow{caption="..."} ... ``` ``
  - `spec_floats`
* - Traceability relations
  - `> traceability: [HLR-013](@)`
  - `spec_relations`
* - Generated views
  - `` `test_results_matrix:` ``
  - `spec_views`
```

## Scope of Structural Verification

### Verification targets structure, not interpretation

The verification layer implemented by SpecCompiler is intentionally narrow. Source documents remain natural-language artifacts, and the compiler does not attempt to prove whether a requirement is correct, complete with respect to stakeholder intent, or behaviorally adequate. Its task is to check whether the document obeys a declared structural model.

This distinction matters for the claims made in this report. When SpecCompiler accepts a specification, it guarantees only that the compiled artifact is free of the structural violations covered by the active proof views. It does not guarantee that the underlying prose is unambiguous, complete, or correct with respect to domain intent.

### Structural obligations captured by the model

Within that scope, the system can check a substantial class of document defects:

- **Type validity**: whether specifications, objects, floats, relations, and views correspond to registered types.
- **Attribute conformance**: whether required attributes exist, whether multiplicities are respected, and whether values can be cast to the declared datatype or enum.
- **Reference resolution**: whether links resolve to unique targets and whether unresolved or ambiguous references remain.
- **Endpoint compatibility**: whether a relation connects admissible source and target kinds according to the registered relation types.
- **Generated artifact integrity**: whether views materialize successfully and whether externally rendered floats produce the expected output.
- **Project-specific coverage rules**: whether model-specific proof views, such as requirement-to-verification coverage, return any counterexamples.

These obligations are structural because they can be stated over finite sets of entities and relations already present in the compiled IR.

### What remains outside the compiler's scope

The following questions remain outside the scope of the present approach:

- whether a requirement states the correct system behavior;
- whether the prose is sufficiently precise for a given certification context;
- whether the set of requirements is complete with respect to unstated stakeholder needs;
- whether two requirements are behaviorally inconsistent unless that inconsistency is encoded as a structural rule.

The report therefore treats verification as a support activity for review, not as a replacement for engineering analysis.

### Why this limited scope is still useful

This limited scope is nevertheless valuable. In many document review processes, a large fraction of findings are repetitive and structural. Removing those findings before inspection improves signal-to-noise ratio and allows reviewers to concentrate on the issues that genuinely require domain expertise. For this reason, structural verification is worthwhile even without any strong claim about full interpretation of the prose.

## SpecCompiler and the Current Type System

The authoring language accepted by SpecCompiler is defined by the currently loaded type system. In this codebase, different loaded model stacks define different source languages. The `default + sw_docs` stack used in the running example below illustrates typed engineering artifacts and inferred relations, while the ABNT stack used to render this report contributes academic-document structure and generated sections such as `LIST_OF_FIGURES`, `LIST_OF_TABLES`, and `SIGLA_LIST`.

### The type system defines the current language

SpecCompiler does not rely on a fixed, monolithic grammar for engineering document kinds. Instead, it loads Lua modules from model directories and registers their exported definitions in the database before document parsing begins. The loaded type system therefore defines what counts as a valid specification type, object type, float type, relation type, or view type in a given build.

```list-table:rtf-type-categories{caption="Type categories loaded into Gamma"}
> header-rows: 1
> aligns: l,l,l,l

* - Category
  - Model directory
  - Module export
  - Registered table
* - Specifications
  - `models/*/types/specifications/`
  - `M.specification`
  - `spec_specification_types`
* - Objects
  - `models/*/types/objects/`
  - `M.object`
  - `spec_object_types`
* - Floats
  - `models/*/types/floats/`
  - `M.float`
  - `spec_float_types`
* - Relations
  - `models/*/types/relations/`
  - `M.relation`
  - `spec_relation_types`
* - Views
  - `models/*/types/views/`
  - `M.view`
  - `spec_view_types`
```

The same loading step also registers attribute definitions, datatypes, enum values, and optional handlers. As a result, the language definition is available inside the IR itself rather than being scattered across ad hoc parser branches.

### A representative loaded type system

The engineering configuration used in the running example is layered. The `default` model provides generic document structure and shared mechanisms; the `sw_docs` model extends it with software-documentation types and domain-specific views.

```list-table:rtf-current-type-system{caption="Representative entries in a default plus sw_docs configuration"}
> header-rows: 1
> aligns: l,l,l

* - Category
  - Default layer
  - `sw_docs` extension layer
* - Specifications
  - `SPEC`
  - `SRS`, `SDD`, `SVC`, `SUM`, `TRR`
* - Objects
  - `SECTION`
  - `TRACEABLE`, `HLR`, `LLR`, `NFR`, `FD`, `SF`, `CSC`, `CSU`, `VC`, `TR`, `DD`, `DIC`, `SYMBOL`
* - Floats
  - `FIGURE`, `TABLE`, `LISTING`, `PLANTUML`, `CHART`, `MATH`
  - domain-specific use inherits default float types
* - Relations
  - `PID_REF`, `LABEL_REF`, `XREF_FIGURE`, `XREF_TABLE`, `XREF_LISTING`, `XREF_MATH`, `XREF_CITATION`
  - `TRACES_TO`, `BELONGS`, `REALIZES`, `VERIFIES`, `XREF_DIC`, `XREF_DECOMPOSITION`
* - Views
  - `TOC`, `LOF`, `ABBREV`, `ABBREV_LIST`, `GAUSS`, `MATH_INLINE`
  - `TRACEABILITY_MATRIX`, `TEST_RESULTS_MATRIX`, `TEST_EXECUTION_MATRIX`, `REQUIREMENTS_SUMMARY`, `COVERAGE_SUMMARY`, `CSC_DECOMPOSITION`
```

This layering is significant for language design. The default model establishes stable structural categories such as `SPEC`, `SECTION`, `FIGURE`, or `TOC`, while the `sw_docs` domain model introduces engineering-specific types such as `HLR`, `VC`, and `VERIFIES` without modifying the compiler core. The same mechanism is what allows the ABNT model to add academic-document objects and views on top of the same compiler runtime.

### Controlled extension through inheritance

The current type system uses single inheritance through the `extends` field. This allows the language to grow by specialization while preserving a compact core. Selected examples illustrate the mechanism:

```list-table:rtf-inheritance-examples{caption="Selected type definitions in the default plus sw_docs example stack"}
> header-rows: 1
> aligns: l,l,l

* - Type
  - Extends
  - Structural role
* - `SECTION`
  - -
  - default composite object type for numbered document structure; optional `description`
* - `TRACEABLE`
  - `SECTION`
  - base traceable object type; contributes inherited `status` enum
* - `HLR`
  - `TRACEABLE`
  - high-level requirement with `pid_prefix = HLR`, `priority`, and optional `rationale`
* - `VC`
  - `TRACEABLE`
  - verification case with required `objective` and `verification_method`, plus optional execution attributes
* - `VERIFIES`
  - `PID_REF`
  - relation inferred from `VC.traceability` links targeting `HLR` or `LLR`
```

Two details are technically important in this example configuration. First, inheritance propagates attributes into the child type environment, so an `HLR` inherits `status` from `TRACEABLE` even though it also defines its own local attributes such as `priority`. Second, relation typing is driven by the loaded type system rather than by explicit markup in the source. For example, a `traceability` attribute in a `VC` that points to an `HLR` is compiled as a `VERIFIES` relation because that rule is declared in the relation type tables.

### How SpecCompiler turns the current type system into Spec-IR

SpecCompiler first loads the type system, then lowers document syntax into the corresponding content tables, and finally verifies the resulting database. The process can be summarized as follows:

```list-table:rtf-compiler-phases{caption="How SpecCompiler turns the source language into Spec-IR"}
> header-rows: 1
> aligns: l,l,l

* - Step
  - Main operation
  - Primary tables affected
* - Model loading
  - load type modules, register attributes and enums, propagate inheritance, register handlers
  - `spec_*_types`, `spec_attribute_types`, `datatype_definitions`, `enum_values`
* - INITIALIZE
  - lower H1/H2-H6 headers, blockquote attributes, code-block floats, links, and view directives into content records
  - `specifications`, `spec_objects`, `spec_floats`, `spec_attribute_values`, `spec_relations`, `spec_views`
* - ANALYZE
  - resolve targets, infer concrete relation types, and cast attribute values
  - `spec_relations`, `spec_attribute_values`
* - TRANSFORM
  - render floats, materialize views, assign numbering, and rewrite links in stored AST fragments
  - `spec_floats`, `spec_views`, AST-bearing columns
* - VERIFY
  - execute proof views and collect counterexamples
  - generated SQL views over the Spec-IR tables
* - EMIT
  - reassemble AST fragments and invoke Pandoc writers
  - output artifacts produced only after successful verification
```

The analyze phase is where the compiler becomes more than a parser. `@` links are resolved by the base `PID_REF` mechanism, which searches first within the same specification and then across documents. `#` links are resolved by the base `LABEL_REF` mechanism, which applies scoped lookup from local context to specification scope and then to global scope. Concrete relation types such as `VERIFIES` or `XREF_FIGURE` are inferred from the selector, the source attribute, the source type, and the resolved target type.

The result is a model-defined specification language whose accepted constructs are compiled into relational facts, then checked against the same type system that defined them.

## Spec-IR: Relational Intermediate Representation

Document compilation for engineering artifacts can be understood in three broad regimes:

1. **Concrete input to concrete output**. Traditional document systems such as LaTeX, Word, or static site generators transform source into output without exposing a persistent verification-oriented IR.
2. **Structural IR**. Pandoc introduces a generic AST that decouples readers from writers and normalizes document syntax across formats [pandoc](@cite).
3. **Typed verification IR**. Spec-IR lowers selected document constructs into typed relational tables so that structural obligations can be stated and checked explicitly.

Pandoc is essential in this architecture, but it is intentionally generic. Its AST records headers, links, code blocks, and lists, but does not by itself distinguish whether a given heading denotes an `HLR`, a `VC`, or an ordinary section in the active engineering model. Spec-IR adds that missing layer by making document types, object kinds, attributes, relations, floats, and views explicit as database facts.

### Why a relational IR?

The choice of a relational IR follows from the nature of the properties being checked. Once the document has been lowered into a finite set of typed entities and relations, the relevant correctness conditions can be expressed as queries over those sets.

#### Verification as set-theoretic reasoning

Many important document checks have the form "all elements of class A satisfy condition B". Missing coverage, broken links, absent mandatory attributes, and ambiguous resolutions all reduce naturally to joins, anti-joins, selections, and projections over finite relations. A relational engine is therefore an appropriate execution substrate for such checks.

#### Declarative correctness and separation of concerns

By expressing constraints as SQL views that return violations, Spec-IR separates the definition of a rule from the procedure used to evaluate it. The compiler core need not embed all project rules procedurally. Instead, it materializes a stable set of facts and delegates constraint evaluation to the database engine. This keeps the trusted core smaller and makes the checking logic inspectable.

#### Closed-world checking and auditability

A compiled specification is a closed world for the purpose of structural verification: all relevant objects, attributes, and relations are expected to be present in the database at verification time. Under this assumption, absence of a tuple can be treated as absence of a fact. This makes anti-join based checking well-defined and supports reproducible audit trails: the same database and the same proof views yield the same counterexamples.

#### Persistence and introspection

Persisting the IR in SQLite makes the compiled specification directly queryable. This enables ad hoc inspection, reporting, dashboard generation, external analysis, and incremental processing without inventing a new query language or a proprietary binary format.

### Two-layer design: type tables vs content tables

Spec-IR separates the language definition from document instances. The type layer defines what may exist; the content layer records what does exist in a given compiled specification.

```list-table:rtf-layers{caption="Spec-IR layers: metamodel vs content"}
> header-rows: 1
> aligns: l,l

* - Layer
  - Representative tables
* - Type system (Gamma)
  - `spec_specification_types`, `spec_object_types`, `spec_float_types`, `spec_relation_types`, `spec_view_types`, `spec_attribute_types`, `datatype_definitions`, `enum_values`
* - Content (instances)
  - `specifications`, `spec_objects`, `spec_floats`, `spec_relations`, `spec_views`, `spec_attribute_values`
```

This separation is essential to extensibility. Changing the type layer changes the accepted language and verification environment without requiring changes to the stored content schema.

### Spec-IR vs. ReqIF: verification substrate vs exchange format

For readers familiar with ReqIF, the resemblance is deliberate but the role is different. ReqIF is primarily an interchange format for exchanging requirements data between tools [ebert2012reqif;reqif2016](@cite). Spec-IR is primarily a compiler IR for analysis, transformation, and verification.

The distinction has practical consequences:

- **Validation model**: ReqIF ensures exchange-level structural consistency, whereas Spec-IR is paired with executable proof views for project-specific structural rules.
- **Query model**: ReqIF typically requires tool-specific import logic; Spec-IR is directly queryable through SQL.
- **Treatment of non-textual content**: floats and generated views are first-class records in Spec-IR rather than opaque attachments.
- **Auditability**: a Spec-IR database can contain both the document facts and the active type environment used to judge them.

The two are therefore complementary. ReqIF is suitable as an interoperability format; Spec-IR is suitable as a verification-oriented working representation.

### From Gamma to proof views: making the type system executable

The type system becomes operational when its constraints are compiled into proof views. Over a finite universe `math: U`, a structural rule can be written in the following canonical form:

```math:rtf-constraint-canonical{caption="Constraint and corresponding violation set"}
C := (AA x in U. P(x) => Q(x)), "Viol"(C) := { x in U : P(x) and not Q(x) }
```

In practice, the proof view implements `"Viol"(C)` directly. Each returned row is a counterexample to the intended invariant.

Consider the rule that every `HLR` must be covered by at least one `VC` through a `VERIFIES` relation. Let:

- `math: HLR(x)` hold when `spec_objects` contains an object `x` with `type_ref = 'HLR'`;
- `math: VC(y)` hold when `spec_objects` contains an object `y` with `type_ref = 'VC'`;
- `math: VERIFIES(y, x)` hold when `spec_relations` contains a relation from `y` to `x` with `type_ref = 'VERIFIES'`.

Then the intended constraint is:

```math:rtf-hlr-vc-constraint{caption="Every HLR has at least one VC witness"}
AA x. "HLR"(x) => EE y. ("VC"(y) and "VERIFIES"(y, x))
```

and the corresponding violation set is:

```math:rtf-hlr-vc-viol{caption="Violation set for missing HLR to VC coverage"}
"Viol"(C_"HLR_to_VC") := { x : "HLR"(x) and not (EE y. ("VC"(y) and "VERIFIES"(y, x))) }
```

In SQL, the proof view is an anti-join over the compiled tables:

```src.sql:rtf-orphan-reqs{caption="HLRs not verified by any VC"}
SELECT so.id, so.pid, so.title_text, so.from_file, so.start_line
FROM spec_objects so
WHERE so.type_ref = 'HLR'
  AND NOT EXISTS (
    SELECT 1
    FROM spec_relations sr
    JOIN spec_objects svc ON svc.id = sr.source_object_id
    WHERE sr.target_object_id = so.id
      AND sr.type_ref = 'VERIFIES'
      AND svc.type_ref = 'VC'
  );
```

Each row returned by this query is a concrete defect: an `HLR` present in the compiled document set for which no admissible `VC` witness exists. The empty result set is therefore the success condition for this particular rule.

With this correspondence in place, well-typedness can be stated operationally:

```math:rtf-welltyped-def{caption="Well-typedness with respect to Gamma"}
"WellTyped"_Gamma(IR) <=> AA V in "ProofViews"(Gamma). V(IR) = O/
```

That is, a specification is well-typed precisely when every proof view derived from the active type environment returns the empty set. This is a strong result, but only within the restricted scope adopted throughout this report: absence of the structural violations encoded by the active proof-view set.

## References

<!-- Bibliografia gerada automaticamente via citeproc a partir de references.bib -->
