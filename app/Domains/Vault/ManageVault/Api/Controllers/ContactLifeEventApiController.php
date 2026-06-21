<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageLifeEvents\Services\CreateLifeEvent;
use App\Domains\Contact\ManageLifeEvents\Services\CreateTimelineEvent;
use App\Domains\Contact\ManageLifeEvents\Services\DestroyLifeEvent;
use App\Domains\Contact\ManageLifeEvents\Services\ToggleLifeEvent;
use App\Domains\Contact\ManageLifeEvents\Services\UpdateLifeEvent;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Life events
 *
 * A life event always lives inside a timeline event. For the mobile client we
 * create one timeline event per life event and enroll the contact as a
 * participant, mirroring the web "add life event" flow.
 */
class ContactLifeEventApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $base = $this->baseData($request, $vaultId, $contactId);
        $vaultData = [
            'account_id' => $base['account_id'],
            'author_id' => $base['author_id'],
            'vault_id' => $base['vault_id'],
        ];

        // CreateTimelineEvent reads the label from the `summary` key (upstream).
        $timeline = (new CreateTimelineEvent)->execute($vaultData + [
            'summary' => $request->input('summary'),
            'started_at' => $request->input('happened_at'),
        ]);

        (new CreateLifeEvent)->execute($vaultData + [
            'timeline_event_id' => $timeline->id,
            'life_event_type_id' => $request->input('life_event_type_id'),
            'summary' => $request->input('summary'),
            'description' => $request->input('description'),
            'happened_at' => $request->input('happened_at'),
            'costs' => $request->input('costs'),
            'currency_id' => $request->input('currency_id'),
            'participant_ids' => [$contactId],
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $timelineId, string $lifeEventId)
    {
        $base = $this->baseData($request, $vaultId, $contactId);

        (new UpdateLifeEvent)->execute([
            'account_id' => $base['account_id'],
            'author_id' => $base['author_id'],
            'vault_id' => $base['vault_id'],
            'timeline_event_id' => (int) $timelineId,
            'life_event_id' => (int) $lifeEventId,
            'life_event_type_id' => $request->input('life_event_type_id'),
            'summary' => $request->input('summary'),
            'description' => $request->input('description'),
            'happened_at' => $request->input('happened_at'),
            'costs' => $request->input('costs'),
            'currency_id' => $request->input('currency_id'),
            'participant_ids' => [$contactId],
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $timelineId, string $lifeEventId)
    {
        $base = $this->baseData($request, $vaultId, $contactId);

        (new DestroyLifeEvent)->execute([
            'account_id' => $base['account_id'],
            'author_id' => $base['author_id'],
            'vault_id' => $base['vault_id'],
            'timeline_event_id' => (int) $timelineId,
            'life_event_id' => (int) $lifeEventId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function toggle(Request $request, string $vaultId, string $contactId, string $timelineId, string $lifeEventId)
    {
        $base = $this->baseData($request, $vaultId, $contactId);

        (new ToggleLifeEvent)->execute([
            'account_id' => $base['account_id'],
            'author_id' => $base['author_id'],
            'vault_id' => $base['vault_id'],
            'timeline_event_id' => (int) $timelineId,
            'life_event_id' => (int) $lifeEventId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
