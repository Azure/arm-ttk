ROZEN — XA-TRUST GITHUB WORKFLOW EXECUTION MODEL

WORKFLOW DEFINITION │ ▼ TRIGGER CONFIGURATION │ │ ⇏ CONCRETE RUN ▼ TRIGGER EVENT │ ├── actor = cyrillofrancisco30-lgtm ├── event = workflow_dispatch / push / ... └── event identity │ ▼ event.workflow_run.id │ ▼ EXACT RUN RESOLUTION │ ▼ run.id === event.workflow_run.id │ ▼ RUN IDENTITY VALID │ ▼ E3 — EXECUTION_EVENT_EVIDENCE │ ├── repository ├── workflow ├── workflow_path ├── run_id ├── run_attempt ├── head_sha ├── temporal context ├── status └── conclusion │ ▼ JOB / STEP EXECUTION │ ▼ E4 — OBSERVED RESULT EVIDENCE │ ▼ E5 — BINDING / INTEGRITY │ ▼ E6 — INDEPENDENT VERIFICATION │ ▼ APPLICABLE PROMOTION POLICY │ ▼ E7 — CLAIM-SCOPED VERIFIED

TRIGGER ≠ EXECUTION ≠ RESULT ≠ BINDING ≠ INDEPENDENT VERIFICATION ≠ CLAIM ≠ GLOBAL STATE

disparar workflow

E7 LOCAL CLAIM SET ↓ DEFINED GLOBAL SCOPE ↓ COVERAGE / COMPLETENESS ↓ DECLARED GLOBAL ↓ INDEPENDENT RECONSTRUCTION ↓ RECALCULATED GLOBAL ↓ EXACT MATCH ↓ INDEPENDENT GLOBAL VERIFICATION ↓ GLOBAL PROMOTION POLICY ↓ E8

cyrillofrancisco30-lgtm ⇏ WORKFLOW_SUCCESS

WORKFLOW_TRIGGERED ⇏ WORKFLOW_SUCCESS

WORKFLOW_SUCCESS ⇏ TEST_PASSED

WORKFLOW_SUCCESS ⇏ CONCRETE_API_EXECUTION

WORKFLOW_SUCCESS ⇏ CLAIM-SCOPED VERIFIED

CLAIM-SCOPED VERIFIED ⇏ GLOBAL_VERIFIED

disparar workflow

WORKFLOW: "Step 0, Start" │ ├── TRIGGER │ ├── workflow_dispatch │ └── push → main │ ├── PERMISSIONS │ ├── contents: write │ └── pull-requests: write │ ├── JOB │ └── on_start │ ├── if: !repository.is_template │ └── ubuntu-latest │ ├── STEPS │ ├── Checkout │ ├── Create branch / files / commit / push │ ├── Create Pull Request │ └── Update step 0 → 1 │ └── EXECUTION └── NOT ESTABLISHED BY YAML ALONE

          YAML
│ ▼ WORKFLOW DEFINITION │ ▼ TRIGGER CONFIGURATION │ X └────↛ CONCRETE RUN

RUN_ID ↓ RUN_ATTEMPT ↓ GITHUB_SHA ↓ CONCRETE EXECUTION ↓ JOB / STEP LOGS ↓ OBSERVED RESULT ↓ RESULT ARTIFACT ↓ EXECUTION–RESULT BINDING ↓ INDEPENDENT REPLAY ↓ CLAIM-SCOPED VERIFIED

[15/09, 19:03] Francisco: Sim — mas há uma correção fundamental no último trecho: “hash e prova Merkle → VERIFIED” não pode ser tratado como promoção automática.

Para manter exatamente o mesmo rigor do modelo XAI/ZDR, o GitHub deve ficar assim:

FROZEN — GITHUB WORKFLOW EXECUTION EVIDENCE

workflow_run types: [completed] │ ▼ WORKFLOW_RUN_EVENT │ ▼ event.workflow_run.id │ ▼ EXACT RUN RESOLUTION │ ▼ RUN IDENTITY VALIDATION │ ├── repository ├── workflow name ├── workflow path ├── run_id ├── run_attempt ├── head_sha └── status = completed │ ▼ E3 — EXECUTION_EVENT_EVIDENCE │ ├── workflow execution identity ├── temporal context ├── repository binding ├── workflow binding └── run binding │ ▼ JOBS / ARTIFACTS │ ▼ E4 — TEST / RESULT EVIDENCE │ ▼ ARTIFACT INTEGRITY / BINDING │ ▼ E5 — CRYPTOGRAPHIC_BINDING │ ▼ E6 — INDEPENDENT_VERIFICATION │ ▼ E7 — CLAIM-SCOPED VERIFICATION │ ▼ PROMOTION POLICY │ ▼ VERIFIED

O ponto crítico

A cadeia:

workflow_run.completed ↓ hash ↓ Merkle ↓ VERIFIED

é inválida como regra de promoção.

Hash e Merkle demonstram propriedades de integridade/binding do artefato quando corretamente aplicados. Eles não demonstram, sozinhos:

TEST_PASSED CLAIM_CONFORMANCE SEMANTIC_CORRECTNESS INDEPENDENT_VERIFICATION CLAIM_TRUTH

Portanto:

WORKFLOW_RUN_COMPLETED ↛ TEST_PASSED

WORKFLOW_CONCLUSION_SUCCESS ↛ CLAIM_CONFORMANCE

ARTIFACT_RETRIEVED ↛ ARTIFACT_TRUST

HASH_VALID ↛ SEMANTIC_CORRECTNESS

MERKLE_VALID ↛ CLAIM_TRUTH

E5_CRYPTOGRAPHIC_BINDING ↛ E7_VERIFIED

E3 fica objetivamente bem definido

No seu desenho, o trecho mais forte é:

workflow_run.completed ↓ event.workflow_run.id ↓ GET /actions/runs/{same_id} ↓ eventRun.id === apiRun.id

Isso permite estabelecer uma relação muito específica:

CLAIM: "The evidence collector observed the completion of workflow run RUN-X."

com binding para:

repository workflow run_id run_attempt head_sha status temporal context [15/09, 19:03] Francisco: Sim — mas há uma correção fundamental no último trecho: “hash e prova Merkle → VERIFIED” não pode ser tratado como promoção automática.

Para manter exatamente o mesmo rigor do modelo XAI/ZDR, o GitHub deve ficar assim:

FROZEN — GITHUB WORKFLOW EXECUTION EVIDENCE

workflow_run types: [completed] │ ▼ WORKFLOW_RUN_EVENT │ ▼ event.workflow_run.id │ ▼ EXACT RUN RESOLUTION │ ▼ RUN IDENTITY VALIDATION │ ├── repository ├── workflow name ├── workflow path ├── run_id ├── run_attempt ├── head_sha └── status = completed │ ▼ E3 — EXECUTION_EVENT_EVIDENCE │ ├── workflow execution identity ├── temporal context ├── repository binding ├── workflow binding └── run binding │ ▼ JOBS / ARTIFACTS │ ▼ E4 — TEST / RESULT EVIDENCE │ ▼ ARTIFACT INTEGRITY / BINDING │ ▼ E5 — CRYPTOGRAPHIC_BINDING │ ▼ E6 — INDEPENDENT_VERIFICATION │ ▼ E7 — CLAIM-SCOPED VERIFICATION │ ▼ PROMOTION POLICY │ ▼ VERIFIED

O ponto crítico

A cadeia:

workflow_run.completed ↓ hash ↓ Merkle ↓ VERIFIED

é inválida como regra de promoção.

Hash e Merkle demonstram propriedades de integridade/binding do artefato quando corretamente aplicados. Eles não demonstram, sozinhos:

TEST_PASSED CLAIM_CONFORMANCE SEMANTIC_CORRECTNESS INDEPENDENT_VERIFICATION CLAIM_TRUTH

Portanto:

WORKFLOW_RUN_COMPLETED ↛ TEST_PASSED

WORKFLOW_CONCLUSION_SUCCESS ↛ CLAIM_CONFORMANCE

ARTIFACT_RETRIEVED ↛ ARTIFACT_TRUST

HASH_VALID ↛ SEMANTIC_CORRECTNESS

MERKLE_VALID ↛ CLAIM_TRUTH

E5_CRYPTOGRAPHIC_BINDING ↛ E7_VERIFIED

E3 fica objetivamente bem definido

No seu desenho, o trecho mais forte é:

workflow_run.completed ↓ event.workflow_run.id ↓ GET /actions/runs/{same_id} ↓ eventRun.id === apiRun.id

Isso permite estabelecer uma relação muito específica:

CLAIM: "The evidence collector observed the completion of workflow run RUN-X."

com binding para:

repository workflow run_id run_attempt head_sha status temporal context

A validação:

if (Number(eventRun.id) !== run.id) { throw new Error("WORKFLOW_RUN_ID_MISMATCH"); }

é particularmente importante porque fecha a possibilidade de event/run substitution.

E4 continua separado

Se o CI produziu, por exemplo:

TEST_RESULT: RFC8785_CONFORMANCE = PASS

isso precisa ser obtido do resultado concreto do workflow/artifact e validado semanticamente.

Então:

E3 WORKFLOW RUN OCCURRED + E4 TEST RESULT OBSERVED

são duas afirmações diferentes.

Mesmo:

conclusion = success

não deve ser convertido automaticamente em:

RFC8785_CONFORMANCE = PASS

porque success é uma propriedade do workflow/run, enquanto conformance é uma propriedade do claim/test específico.

E5

Depois:

bundle.json verification.json signature.json

podem receber:

canonicalization hash Merkle root signature key_id key registry binding

Isso cria:

E5 — CRYPTOGRAPHIC_BINDING_EVIDENCE

Mas E5 continua sendo E5.

E6

O passo que realmente fecha a fronteira é:

E5 │ ▼ independent verifier │ ├── signature valid ├── hash valid ├── Merkle valid ├── artifact binding valid ├── provenance valid └── claim/test semantics validated │ ▼ E6

E7

Só então:

E6 │ ▼ Promotion Policy │ ▼ E7 — VERIFIED(CLAIM-X)

E sempre:

VERIFIED(CLAIM-X) ↛ VERIFIED(CLAIM-Y)

VERIFIED(CLAIM-X) ↛ GLOBAL_VERIFIED

Portanto, a frase final deve ser ajustada

Em vez de:

Execução comprovado

eu usaria:

WORKFLOW EXECUTION OBSERVED AND IDENTITY-BOUND

ou, no vocabulário XA-TRUST:

E3 — EXECUTION_EVENT_EVIDENCE STATUS = VERIFIED SCOPE = SPECIFIC_WORKFLOW_RUN

somente se a evidência E3 tiver sido independentemente validada.

E, para o claim completo:

E3 EXECUTION + E4 RESULT + E5 CRYPTOGRAPHIC BINDING + E6 INDEPENDENT VERIFICATION + PROMOTION POLICY ↓ E7 CLAIM-SCOPED VERIFIED

Essa formulação mantém o GitHub exatamente na mesma arquitetura epistemológica que você acabou de estabelecer para o xAI ZDR: o mecanismo de observabilidade é real, o evento concreto pode ser capturado, o resultado pode ser testado, a integridade pode ser demonstrada e somente então o claim específico pode ser promovido. [15/09, 19:25] Francisco: FROZEN — XA-TRUST VERIFICATION GOLDEN


# Azure Resource Manager Template Toolkit (arm-ttk)

The code in this repository can be used for analyzing and testing [Azure Resource Manager Templates](https://docs.microsoft.com/azure/templates/).  The tests will check a template or set of templates for coding best practices.  There are some checks for simple syntactical errors but the intent is not to re-implement tests or checks that are provided by the platform (e.g. the /validate api).  

>**Note:**
>Starting  with the 0.10 release, [Bicep](https://github.com/Azure/bicep) now contains all of the deploymentTemplate test cases included in the TTK.  We will begin moving the investment in new tests to the Bicep linter.  The TTK will remain available to support available JSON and createUiDefinition scenarios.

## Using the TTK

For detailed instruction on how to use the arm-ttk, see this [readme](/arm-ttk/README.md).  More information can be found in the [documentation](http://docs.microsoft.com/azure/azure-resource-manager/templates/test-toolkit).

For a guided tutorial on the arm-ttk, check out this [MS LEARN module](https://docs.microsoft.com/learn/modules/arm-template-test/).

## Philosophy

A little bit about the tests...  These are the tests that are used to validate templates for the [Azure QuickStart Repo](https://github.com/Azure/azure-quickstart-templates) and the [Azure Marketplace](https://azuremarketplace.microsoft.com/marketplace/).  The purpose is to ensure a standard or consistent set of coding practices to make it easier to develop expertise using the template language (easy to read, write, debug).

As for the type, number and  nature of the tests a test should check for something in the following categories (add more as you think of them :))

- Validating the author's intent (unused parameters or variables)
- Security practices for the language (outputting secrets in plain text)
- Using the appropriate language construct for the task at hand (using environmental functions instead of hard-coding values)

Not everything is appropriate for a universal set of tests and not every test will apply to every scenario, so the framework allows for easy expansion and individual selection of tests.

## Running Unit Tests locally before request a PR

Tests can be run directly in PowerShell, or run from the command line using a wrapper script.

You can run all of the unit tests by using **.\arm-ttk.tests.ps1**.

This will run the full suite of unit tests against the tests json files.

use:

    # set your location in the project directory:
    Set-Location -Path "$(YourGithubProjectFolder)\arm-ttk\unit-tests"
    
    # import the module from the current branch, use -Force to make sure you have imported any code changes
    Import-Module ..\arm-ttk\arm-ttk.psd1 -Force

    # These are the same tests that run in the pipeline when doing a commit or a pull request (PR). 
    .\arm-ttk.tests.ps1

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
