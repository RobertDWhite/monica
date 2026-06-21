<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageAvatar\Services\DestroyAvatar;
use App\Domains\Contact\ManageAvatar\Services\UpdatePhotoAsAvatar;
use App\Models\File;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * @group Contact management
 *
 * @subgroup Avatar
 *
 * Local (multipart) avatar upload — bypasses Uploadcare by writing the File
 * row directly to the public disk (same approach as ModuleAvatarLocalController).
 */
class ContactAvatarApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $request->validate(['photo' => 'required|image|max:10240']);

        $uploaded = $request->file('photo');
        $path = $uploaded->store('contact-avatars', 'public');

        $file = File::create([
            'vault_id' => $vaultId,
            'uuid' => (string) Str::uuid(),
            'original_url' => Storage::disk('public')->url($path),
            'cdn_url' => Storage::disk('public')->url($path),
            'mime_type' => $uploaded->getMimeType(),
            'name' => $uploaded->getClientOriginalName(),
            'type' => File::TYPE_AVATAR,
            'size' => $uploaded->getSize(),
        ]);

        (new UpdatePhotoAsAvatar)->execute($this->baseData($request, $vaultId, $contactId) + [
            'file_id' => $file->id,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId)
    {
        (new DestroyAvatar)->execute($this->baseData($request, $vaultId, $contactId));

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
