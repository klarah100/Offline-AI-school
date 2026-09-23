# OfflineAI School — Draft Privacy Notice

**Status: draft for legal and school-policy review.**

OfflineAI School is designed to provide personalized learning in low-connectivity environments.

## Information the product may process

Depending on the deployment, the platform may process a learner's display name, grade/level, preferred language, learning goals, question attempts, answers, correctness, practice duration, topic progress, and synchronization metadata.

The product should not collect precise location, contacts, device identifiers, advertising identifiers, or other unrelated information unless a documented product requirement and approved privacy review requires it.

## Why information is used

Learning information is used to:

- provide lessons and practice;
- generate learning recommendations;
- show learner progress;
- synchronize approved learning records to a school service;
- improve reliability and educational usefulness during a controlled pilot.

## Offline operation

Core learning records are stored locally so that lessons and practice can continue without internet access. Synchronization occurs only when connectivity and an authenticated server session are available.

## Account security

Authentication credentials and session tokens are protected using secure storage on supported devices. Server access is protected by authenticated API requests and role/school authorization.

## Data deletion

Authenticated learners can request deletion of their online account and synchronized learning records through the product. School deployments should also define how school-held records are retained or deleted.

## Children and schools

Deployments involving children must use the consent, safeguarding, retention and access procedures required by the relevant school, jurisdiction and service provider.

## AI

Where AI services are used, production deployments must minimize the data sent to external model providers, avoid sending unnecessary personal information, use approved providers, and document whether prompts or outputs are retained.

This draft does not by itself establish legal compliance. A qualified privacy/legal reviewer should approve the final notice, consent language, retention schedule and school agreements before production launch.
