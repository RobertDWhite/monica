<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageCalls\Services\CreateCall;
use App\Domains\Contact\ManageCalls\Services\DestroyCall;
use App\Domains\Contact\ManageCalls\Services\UpdateCall;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Calls
 */
class ContactCallApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateCall)->execute($this->baseData($request, $vaultId, $contactId) + [
            'called_at' => $request->input('called_at'),
            'type' => $request->input('type'),
            'who_initiated' => $request->input('who_initiated'),
            'duration' => $request->input('duration'),
            'description' => $request->input('description'),
            'answered' => $request->input('answered'),
            'call_reason_id' => $request->input('call_reason_id'),
            'emotion_id' => $request->input('emotion_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $callId)
    {
        (new UpdateCall)->execute($this->baseData($request, $vaultId, $contactId) + [
            'call_id' => (int) $callId,
            'called_at' => $request->input('called_at'),
            'type' => $request->input('type'),
            'who_initiated' => $request->input('who_initiated'),
            'duration' => $request->input('duration'),
            'answered' => $request->input('answered'),
            'call_reason_id' => $request->input('call_reason_id'),
            'emotion_id' => $request->input('emotion_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $callId)
    {
        (new DestroyCall)->execute($this->baseData($request, $vaultId, $contactId) + [
            'call_id' => (int) $callId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
