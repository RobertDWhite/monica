<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageGoals\Services\CreateGoal;
use App\Domains\Contact\ManageGoals\Services\DestroyGoal;
use App\Domains\Contact\ManageGoals\Services\ToggleStreak;
use App\Domains\Contact\ManageGoals\Services\UpdateGoal;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Goals
 */
class ContactGoalApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateGoal)->execute($this->baseData($request, $vaultId, $contactId) + [
            'name' => $request->input('name'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $goalId)
    {
        (new UpdateGoal)->execute($this->baseData($request, $vaultId, $contactId) + [
            'goal_id' => (int) $goalId,
            'name' => $request->input('name'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $goalId)
    {
        (new DestroyGoal)->execute($this->baseData($request, $vaultId, $contactId) + [
            'goal_id' => (int) $goalId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    /**
     * Toggle today's (or a given day's) streak for a goal.
     */
    public function toggleStreak(Request $request, string $vaultId, string $contactId, string $goalId)
    {
        (new ToggleStreak)->execute($this->baseData($request, $vaultId, $contactId) + [
            'goal_id' => (int) $goalId,
            'happened_at' => $request->input('happened_at', now()->format('Y-m-d')),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
