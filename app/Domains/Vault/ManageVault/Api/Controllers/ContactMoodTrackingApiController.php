<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageMoodTrackingEvents\Services\CreateMoodTrackingEvent;
use App\Domains\Contact\ManageMoodTrackingEvents\Services\DestroyMoodTrackingEvent;
use App\Domains\Contact\ManageMoodTrackingEvents\Services\UpdateMoodTrackingEvent;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Mood tracking
 */
class ContactMoodTrackingApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateMoodTrackingEvent)->execute($this->baseData($request, $vaultId, $contactId) + [
            'mood_tracking_parameter_id' => $request->input('mood_tracking_parameter_id'),
            'rated_at' => $request->input('rated_at'),
            'note' => $request->input('note'),
            'number_of_hours_slept' => $request->input('number_of_hours_slept'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $eventId)
    {
        (new UpdateMoodTrackingEvent)->execute($this->baseData($request, $vaultId, $contactId) + [
            'mood_tracking_event_id' => (int) $eventId,
            'mood_tracking_parameter_id' => $request->input('mood_tracking_parameter_id'),
            'rated_at' => $request->input('rated_at'),
            'note' => $request->input('note'),
            'number_of_hours_slept' => $request->input('number_of_hours_slept'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $eventId)
    {
        (new DestroyMoodTrackingEvent)->execute($this->baseData($request, $vaultId, $contactId) + [
            'mood_tracking_event_id' => (int) $eventId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
