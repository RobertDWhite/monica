<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageNotes\Services\CreateNote;
use App\Domains\Contact\ManageNotes\Services\DestroyNote;
use App\Domains\Contact\ManageNotes\Services\UpdateNote;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Notes
 */
class ContactNoteApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateNote)->execute($this->baseData($request, $vaultId, $contactId) + [
            'title' => $request->input('title'),
            'body' => $request->input('body'),
            'emotion_id' => $request->input('emotion_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $noteId)
    {
        (new UpdateNote)->execute($this->baseData($request, $vaultId, $contactId) + [
            'note_id' => (int) $noteId,
            'title' => $request->input('title'),
            'body' => $request->input('body'),
            'emotion_id' => $request->input('emotion_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $noteId)
    {
        (new DestroyNote)->execute($this->baseData($request, $vaultId, $contactId) + [
            'note_id' => (int) $noteId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
