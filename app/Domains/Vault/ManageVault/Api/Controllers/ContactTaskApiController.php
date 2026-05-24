<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageTasks\Services\CreateContactTask;
use App\Domains\Contact\ManageTasks\Services\DestroyContactTask;
use App\Domains\Contact\ManageTasks\Services\ToggleContactTask;
use App\Domains\Contact\ManageTasks\Services\UpdateContactTask;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Tasks
 */
class ContactTaskApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateContactTask)->execute($this->baseData($request, $vaultId, $contactId) + [
            'label' => $request->input('label'),
            'description' => $request->input('description'),
            'due_at' => $request->input('due_at'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $taskId)
    {
        (new UpdateContactTask)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_task_id' => (int) $taskId,
            'label' => $request->input('label'),
            'description' => $request->input('description'),
            'due_at' => $request->input('due_at'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    /**
     * Toggle a task between completed and incomplete.
     */
    public function toggle(Request $request, string $vaultId, string $contactId, string $taskId)
    {
        (new ToggleContactTask)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_task_id' => (int) $taskId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $taskId)
    {
        (new DestroyContactTask)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_task_id' => (int) $taskId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
