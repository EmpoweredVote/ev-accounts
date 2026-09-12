import { Router, Response } from 'express'
import { requireAuth, type AuthenticatedRequest } from '../../middleware/auth.js'
import { fetchAccountData, checkVolunteerRole } from '../services/accountsApi.js'
import {
  assignUserToSlices,
  upsertConnectedProfile,
  assignUnifiedIfNotAssigned,
  assignVolunteerIfEligible,
} from '../services/sliceAssigner.js'

// Civic Spaces slice assignment — folded from civic-spaces services/slice-assignment
// (ev-cto decision 0018). Mounted at /api/civic-spaces (see src/index.ts), so the one real
// endpoint is POST /api/civic-spaces/assign. requireAuth (the engine's single dual-issuer
// verifier) replaces the standalone's own verifyToken copy, which 401'd every WorkOS member
// after the 2026-08-28 cutover — the duplicate is deliberately not reintroduced.

const router = Router()

router.post('/assign', requireAuth, async (req, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest
  const userId = authReq.userId
  const accessToken = authReq.accessToken

  try {
    const [accountData, isVolunteer] = await Promise.all([
      fetchAccountData(accessToken, userId),
      checkVolunteerRole(userId),
    ])

    if (accountData.tier === 'inform') {
      res.status(403).json({ error: 'Connected tier required' })
      return
    }

    await upsertConnectedProfile(
      accountData.id,
      accountData.display_name,
      accountData.account_standing
    )

    const assigned: string[] = []

    // Unified: auto-assign all Connected users (check-before-insert — stable cohort)
    const unifiedSliceId = await assignUnifiedIfNotAssigned(accountData.id)
    if (unifiedSliceId) {
      assigned.push(unifiedSliceId)
    }

    // Volunteer: role-gated — isVolunteer resolved via getCachedUserRoles + checkRole
    // (90s cache on revocation, identical to the old POST /api/roles/check path)
    const volunteerSliceId = await assignVolunteerIfEligible(accountData.id, isVolunteer)
    if (volunteerSliceId) {
      assigned.push(volunteerSliceId)
    }

    // Geo: assignment based on jurisdiction (4 geographic slices)
    if (accountData.jurisdiction !== null) {
      const geoResult = await assignUserToSlices(accountData.id, accountData.jurisdiction)
      assigned.push(...geoResult.assigned)
      if (geoResult.skipped.length > 0) {
        // Not an error — the jurisdiction genuinely lacks that level. Logged because
        // "why do I have no city tab" is otherwise unanswerable from here.
        console.log(`[civic_spaces][assign] no geoid for: ${geoResult.skipped.join(', ')}`)
      }
    }

    if (assigned.length === 0) {
      res.status(200).json({
        status: 'no_jurisdiction',
        message: 'User has no jurisdiction set',
      })
      return
    }

    res.status(200).json({ status: 'assigned', assigned })
  } catch (err) {
    console.error('[civic_spaces][assign] error:', err)
    res.status(500).json({ error: 'Internal server error' })
  }
})

export default router
