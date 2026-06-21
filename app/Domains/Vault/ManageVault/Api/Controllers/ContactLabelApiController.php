<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageLabels\Services\AssignLabel;
use App\Domains\Contact\ManageLabels\Services\RemoveLabel;
use App\Domains\Vault\ManageVaultSettings\Services\CreateLabel;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Labels
 */
class ContactLabelApiController extends ContactModuleApiController
{
    /**
     * Assign an existing label (label_id) to the contact, or create a new
     * label from `name` and then assign it.
     */
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $labelId = $request->input('label_id');

        if (! $labelId) {
            $label = (new CreateLabel)->execute([
                'account_id' => $request->user()->account_id,
                'author_id' => $request->user()->id,
                'vault_id' => $vaultId,
                'name' => $request->input('name'),
                'description' => $request->input('description'),
                'bg_color' => $request->input('bg_color'),
                'text_color' => $request->input('text_color'),
            ]);
            $labelId = $label->id;
        }

        (new AssignLabel)->execute($this->baseData($request, $vaultId, $contactId) + [
            'label_id' => (int) $labelId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $labelId)
    {
        (new RemoveLabel)->execute($this->baseData($request, $vaultId, $contactId) + [
            'label_id' => (int) $labelId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
