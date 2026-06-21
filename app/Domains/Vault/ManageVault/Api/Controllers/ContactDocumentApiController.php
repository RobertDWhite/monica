<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageDocuments\Services\DestroyFile;
use App\Models\File;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * @group Contact management
 *
 * @subgroup Documents
 */
class ContactDocumentApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $request->validate(['document' => 'required|file|max:51200']);

        $uploaded = $request->file('document');
        $path = $uploaded->store('contact-documents', 'public');

        $file = File::create([
            'vault_id' => $vaultId,
            'uuid' => (string) Str::uuid(),
            'original_url' => Storage::disk('public')->url($path),
            'cdn_url' => Storage::disk('public')->url($path),
            'mime_type' => $uploaded->getMimeType(),
            'name' => $uploaded->getClientOriginalName(),
            'type' => File::TYPE_DOCUMENT,
            'size' => $uploaded->getSize(),
        ]);

        $this->findContact($request, $vaultId, $contactId)->files()->save($file);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $fileId)
    {
        (new DestroyFile)->execute($this->baseData($request, $vaultId, $contactId) + [
            'file_id' => (int) $fileId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
