<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageReminders\Services\CreateContactReminder;
use App\Domains\Contact\ManageReminders\Services\DestroyReminder;
use App\Domains\Contact\ManageReminders\Services\UpdateContactReminder;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Reminders
 */
class ContactReminderApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateContactReminder)->execute($this->baseData($request, $vaultId, $contactId) + [
            'label' => $request->input('label'),
            'day' => $request->input('day'),
            'month' => $request->input('month'),
            'year' => $request->input('year'),
            'type' => $request->input('type'),
            'frequency_number' => $request->input('frequency_number'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $reminderId)
    {
        (new UpdateContactReminder)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_reminder_id' => (int) $reminderId,
            'label' => $request->input('label'),
            'day' => $request->input('day'),
            'month' => $request->input('month'),
            'year' => $request->input('year'),
            'type' => $request->input('type'),
            'frequency_number' => $request->input('frequency_number'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $reminderId)
    {
        (new DestroyReminder)->execute($this->baseData($request, $vaultId, $contactId) + [
            'contact_reminder_id' => (int) $reminderId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
